import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class EarthMapPage extends StatefulWidget {
  const EarthMapPage({super.key});

  @override
  EarthMapPageState createState() => EarthMapPageState();
}

class EarthMapPageState extends State<EarthMapPage> {
  late MapboxMap _mapboxMap;
  bool _isMapReady = false;
  late PointAnnotationManager _annotationManager;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    logger.i('Map created.');

    // Initialize the annotation manager
    _annotationManager = await _mapboxMap.annotations.createPointAnnotationManager();

    setState(() {
      _isMapReady = true;
    });
  }

  void _onMapTap(ScreenCoordinate screenPoint) async {
    try {
      // Use `queryRenderedFeatures` to check if the tap intersects with an annotation
      final features = await _mapboxMap.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(screenPoint),
        RenderedQueryOptions(layerIds: [_annotationManager.id]), // Check annotation layer
      );

      if (features.isEmpty) {
        logger.i('No annotation at tap location. Adding new annotation.');
        final mapPoint = await _mapboxMap.coordinateForPixel(screenPoint);
        _addAnnotation(mapPoint); // Directly add the annotation
      } else {
        logger.i('Tap was on an annotation. No new annotation added.');
      }
    } catch (e) {
      logger.e('Error during feature query: $e');
    }
  }

  Future<void> _addAnnotation(Point mapPoint) async {
    logger.i('Adding annotation at: ${mapPoint.coordinates.lat}, ${mapPoint.coordinates.lng}');
    final annotationOptions = PointAnnotationOptions(
      geometry: mapPoint,
      iconSize: 1.0,
      iconImage: "mapbox-check", // Customize with your desired icon
    );

    await _annotationManager.create(annotationOptions);
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthMapPage');
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) { // Detect long press
        final screenPoint = ScreenCoordinate(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        );
        _onMapTap(screenPoint); // Pass screenPoint to _onMapTap
      },
      child: Scaffold(
        body: Stack(
          children: [
            MapWidget(
              cameraOptions: MapConfig.defaultCameraOptions,
              styleUri: MapConfig.styleUri,
              onMapCreated: _onMapCreated,
            ),
            if (_isMapReady)
              Positioned(
                top: 40,
                left: 10,
                child: BackButton(
                  onPressed: () {
                    logger.i('Back button pressed');
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}