// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class StationProfile extends StatefulWidget {
  final int stationId;

  const StationProfile({super.key, required this.stationId});

  @override
  State<StationProfile> createState() => _StationProfilePageState();
}

class _StationProfilePageState extends State<StationProfile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _description = TextEditingController();

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  List<String> workingDays = [];
  LatLng? _selectedLocation;
  File? _profileImage;
  String? _profileImageUrl;

  bool isLoading = true;
  bool hasData = false;
  bool isEditMode = false;

  GoogleMapController? _googleMapController;

  final LatLngBounds tagbilaranBounds = LatLngBounds(
    southwest: LatLng(9.6280, 123.8200),
    northeast: LatLng(9.6800, 123.8800),
  );

  @override
  void initState() {
    super.initState();
    fetchStationDetails();
  }

  // ===========================
  // 🔹 FETCH STATION DETAILS
  // ===========================
  Future<void> fetchStationDetails() async {
    try {
      final response = await http
          .get(Uri.parse("http://10.0.2.2:3000/api/station/${widget.stationId}"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _name.text = data['station_name'] ?? '';
          _contact.text = data['contact_number'] ?? '';
          _address.text = data['address'] ?? '';
          _description.text = data['description'] ?? '';
          workingDays = List<String>.from(data['working_days'] ?? []);

          if (data['opening_time'] != null) {
            _openTime = _parseTime(data['opening_time']);
          }
          if (data['closing_time'] != null) {
            _closeTime = _parseTime(data['closing_time']);
          }

          if (data['latitude'] != null && data['longitude'] != null) {
            _selectedLocation = LatLng(
              double.parse(data['latitude'].toString()),
              double.parse(data['longitude'].toString()),
            );
          }

          // ✅ Profile picture loading
          if (data['profile_picture'] != null &&
              data['profile_picture'].toString().isNotEmpty) {
            _profileImageUrl =
                "http://10.0.2.2:3000/uploads/${data['profile_picture']}";
          }

          // ✅ Simplified logic
          hasData = true;
          isEditMode = false;

          // Optional: only force edit if truly incomplete
          if ((data['address'] == null || data['address'].isEmpty) &&
              (data['latitude'] == null || data['longitude'] == null)) {
            isEditMode = true;
          }

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching station details: $e");
      setState(() => isLoading = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // ===========================
  // 🔹 IMAGE PICKER
  // ===========================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  // ===========================
  // 🔹 TIME PICKER
  // ===========================
  Future<void> _selectTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  // ===========================
  // 🔹 MAP LOCATION SELECT
  // ===========================
  Future<void> _onMapTap(LatLng pos) async {
    if (!tagbilaranBounds.contains(pos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select a location within Tagbilaran City")),
      );
      return;
    }

    List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      _address.text =
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
    }
    setState(() => _selectedLocation = pos);
  }

  // ===========================
  // 🔹 ADDRESS → LOCATION
  // ===========================
  Future<void> _locateAddress(String address) async {
    if (address.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final LatLng newPos = LatLng(loc.latitude, loc.longitude);

        if (!tagbilaranBounds.contains(newPos)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please enter a location within Tagbilaran City")),
          );
          return;
        }

        setState(() => _selectedLocation = newPos);
        _googleMapController?.animateCamera(CameraUpdate.newLatLng(newPos));
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to find that address")),
      );
    }
  }

  // ===========================
  // 🔹 SAVE / UPDATE PROFILE
  // ===========================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2.2:3000/api/station/update-profile"),
    );

    request.fields.addAll({
      'station_id': widget.stationId.toString(),
      'station_name': _name.text,
      'address': _address.text,
      'contact_number': _contact.text,
      'description': _description.text,
      'latitude': _selectedLocation?.latitude.toString() ?? '',
      'longitude': _selectedLocation?.longitude.toString() ?? '',
      'working_days': jsonEncode(workingDays),
      'opening_time': _openTime?.format(context) ?? '',
      'closing_time': _closeTime?.format(context) ?? '',
    });

    if (_profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        _profileImage!.path,
      ));
    }

    final response = await request.send();
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );
      await fetchStationDetails();
      setState(() {
        isEditMode = false;
        hasData = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile.")),
      );
    }
  }

  // ===========================
  // 🔹 UI BUILD
  // ===========================
  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF021526);
    const Color accentBlue = Color(0xFF6EACDA);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: const Text("Station Profile"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6EACDA)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isEditMode
                    ? _buildEditForm(accentBlue)
                    : hasData
                        ? _buildProfileView(accentBlue)
                        : _buildEditForm(accentBlue),
              ),
            ),
      floatingActionButton: hasData && !isEditMode
          ? FloatingActionButton.extended(
              backgroundColor: accentBlue,
              icon: const Icon(Icons.edit),
              label: const Text("Update"),
              onPressed: () => setState(() => isEditMode = true),
            )
          : null,
    );
  }

  // ===========================
  // 🔹 EDIT FORM
  // ===========================
  Widget _buildEditForm(Color accentBlue) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: accentBlue.withValues(alpha: 0.2),
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : null),
                child: _profileImage == null && _profileImageUrl == null
                    ? const Icon(Icons.camera_alt,
                        color: Colors.white54, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField(_name, "Station Name", Icons.store,
                readOnly: true),
            const SizedBox(height: 10),
            _buildTextField(_contact, "Contact Number", Icons.phone),
            const SizedBox(height: 10),
            _buildTextField(
              _address,
              "Address",
              Icons.location_on,
              onChanged: (val) {
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (val == _address.text) _locateAddress(val);
                });
              },
            ),
            const SizedBox(height: 10),
            _buildTextField(_description, "Description", Icons.text_snippet,
                maxLines: 2),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Tap or drag the pin to set location",
                  style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: GoogleMap(
                onMapCreated: (controller) =>
                    _googleMapController = controller,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(9.6423, 123.8531),
                  zoom: 13,
                ),
                onTap: _onMapTap,
                markers: _selectedLocation == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId("selected"),
                          position: _selectedLocation!,
                          draggable: true,
                          onDragEnd: (newPos) async {
                            _selectedLocation = newPos;
                            List<Placemark> placemarks =
                                await placemarkFromCoordinates(
                                    newPos.latitude, newPos.longitude);
                            if (placemarks.isNotEmpty) {
                              final place = placemarks.first;
                              _address.text =
                                  "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
                            }
                            setState(() {});
                          },
                        )
                      },
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Working Days",
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            Wrap(
              children: [
                for (var day in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
                  _buildDayButton(day),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue),
                    onPressed: () => _selectTime(true),
                    child: Text(_openTime == null
                        ? "Set Opening Time"
                        : "Opens: ${_openTime!.format(context)}"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue),
                    onPressed: () => _selectTime(false),
                    child: Text(_closeTime == null
                        ? "Set Closing Time"
                        : "Closes: ${_closeTime!.format(context)}"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14)),
              icon: const Icon(Icons.save),
              label: const Text("Save Profile"),
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ===========================
  // 🔹 VIEW MODE
  // ===========================
  Widget _buildProfileView(Color accentBlue) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: accentBlue.withValues(alpha: 0.2),
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : (_profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                    : null),
            child: _profileImage == null && _profileImageUrl == null
                ? const Icon(Icons.store_mall_directory,
                    size: 60, color: Colors.white70)
                : null,
          ),
          const SizedBox(height: 20),
          _buildInfo("Station Name", _name.text),
          _buildInfo("Contact", _contact.text),
          _buildInfo("Address", _address.text),
          _buildInfo("Description", _description.text),
          _buildInfo("Working Hours",
              "${_openTime?.format(context) ?? '--'} - ${_closeTime?.format(context) ?? '--'}"),
          _buildInfo("Working Days", workingDays.join(", ")),
          const SizedBox(height: 10),
          if (_selectedLocation != null)
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _selectedLocation!, zoom: 13),
                markers: {
                  Marker(
                    markerId: const MarkerId("station"),
                    position: _selectedLocation!,
                  ),
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {int maxLines = 1,
      bool readOnly = false,
      Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (!readOnly && val!.isEmpty) return "Enter $label";
        if (label == "Contact Number" &&
            !RegExp(r'^[0-9+\- ]+$').hasMatch(val ?? '')) {
          return "Enter a valid phone number";
        }
        return null;
      },
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6EACDA)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B263B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6EACDA), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EACDA).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value.isNotEmpty ? value : "—",
              style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildDayButton(String day) {
    final selected = workingDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          selected ? workingDays.remove(day) : workingDays.add(day);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6EACDA) : const Color(0xFF1B263B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6EACDA) : Colors.white24,
          ),
        ),
        child: Text(day,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
