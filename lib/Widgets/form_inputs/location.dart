import 'package:product_shop/Widgets/ensure_visible.dart.dart';
import 'package:product_shop/models/product.dart';
import 'package:product_shop/shared/global_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/location_data.dart';
import 'package:location/location.dart' as geoloc;

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Product product;
  LocationInput(this.setLocation, this.product);
  @override
  State<StatefulWidget> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  LocationData _locationData;
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputController = TextEditingController();
  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.product != null) {
      _getStaticMap(widget.product.location.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void _getStaticMap(String address,
      {geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }
    if (geocode) {
      final Uri uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json',
          {'address': address, 'key': apiKey});
      final http.Response response = await http.get(uri);
      final decodedResponse = json.decode(response.body);
      final formattedAddress =
          decodedResponse['results'][0]['formatted_address'];
      final coords = decodedResponse['results'][0]['geometry']['location'];
      _locationData = LocationData(
          latitude: coords['lat'],
          longitude: coords['lng'],
          address: formattedAddress);
    } else if (lat == null && lng == null) {
      _locationData = widget.product.location;
    } else {
      _locationData =
          LocationData(address: address, latitude: lat, longitude: lng);
    }
    if (mounted) {
      final StaticMapProvider staticMapProvider = StaticMapProvider(apiKey);
      final Uri staticMapuri = staticMapProvider.getStaticUriWithMarkers([
        Marker('position', 'position', _locationData.latitude,
            _locationData.longitude),
      ],
          center: Location(_locationData.latitude, _locationData.longitude),
          width: 500,
          height: 300,
          maptype: StaticMapViewType.roadmap);
      widget.setLocation(_locationData);
      setState(() {
        _addressInputController.text = _locationData.address;
        _staticMapUri = staticMapuri;
      });
    }
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      _getStaticMap(_addressInputController.text);
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json',
        {'latlng': '${lat.toString()},${lng.toString()}', 'key': apiKey});
    final http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    print(decodedResponse);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];
    return formattedAddress;
  }

  void _getUserLocation() async {
    final location = geoloc.Location();
    try {
      final currentLocation = await location.getLocation();
      print(currentLocation);
      final address = await _getAddress(
          currentLocation.latitude, currentLocation.longitude);
      _getStaticMap(address,
          geocode: false,
          lat: currentLocation.latitude,
          lng: currentLocation.longitude);
    } catch (error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Couldn\'t fetch Location'),
              content: Text('Error!!'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okat'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        EnsureVisibleWhenFocused(
          focusNode: _addressInputFocusNode,
          child: TextFormField(
            focusNode: _addressInputFocusNode,
            controller: _addressInputController,
            decoration: InputDecoration(labelText: 'Address'),
            validator: (String value) {
              if (_locationData.address == null || value.isEmpty) {
                return 'No vaild Location Found';
              }
            },
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        FlatButton(
          child: Text('Locate User'),
          onPressed: _getUserLocation,
        ),
        SizedBox(
          height: 10.0,
        ),
        _staticMapUri == null
            ? Container()
            : Image.network(_staticMapUri.toString())
      ],
    );
  }
}