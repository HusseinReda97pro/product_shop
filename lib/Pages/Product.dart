import 'dart:async';

import 'package:product_shop/Widgets/products/product_fab.dart';
import 'package:product_shop/Widgets/ui_elments/title_defult.dart';
import 'package:product_shop/models/product.dart';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';

class ProductPage extends StatelessWidget {
  final Product product;
  ProductPage(this.product);
  void _showMap() {
    final List<Marker> markers = <Marker>[
      Marker('possition', 'possition', product.location.latitude,
          product.location.longitude)
    ];
    final cameraPosition = CameraPosition(
        Location(product.location.latitude, product.location.longitude), 14.0);
    final mapView = MapView();
    mapView.show(
        MapOptions(
            initialCameraPosition: cameraPosition,
            mapViewType: MapViewType.normal,
            title: 'Product Location'),
        toolbarActions: [ToolbarAction('Close', 1)]);
    mapView.onToolbarAction.listen((int id) {
      if (id == 1) {
        mapView.dismiss();
      }
    });
    mapView.onMapReady.listen((_) {
      mapView.setMarkers(markers);
    });
  }

  Widget _buildAddressPriceRow(String address, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: _showMap,
          child: Container(
            width: 300.0,
            child: Text(
              address,
              style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            '|',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Text(
          '\$' + price.toString(),
          style: TextStyle(fontFamily: 'Oswald', color: Colors.grey),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          print('Back button pressed!');
          Navigator.pop(context, false);
          return Future.value(false);
        },
        child: Scaffold(
          // appBar: AppBar(
          //   title: Text(product.title),
          // ),
          body: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                  expandedHeight: 256.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(product.title),
                    background: Hero(
                        tag: product.id,
                        child: FadeInImage(
                          image: NetworkImage(product.image),
                          height: 300,
                          fit: BoxFit.cover,
                          placeholder: AssetImage('assets/loading.png'),
                        )),
                  )),
              SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10.0),
                    child: TitleDefault(product.title),
                  ),
                  _buildAddressPriceRow(
                      product.location.address, product.price),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      product.description,
                      textAlign: TextAlign.center,
                    ),
                  )
                ]),
              )
            ],
          ),

          floatingActionButton: ProductFAB(product),
        ));
  }
}
