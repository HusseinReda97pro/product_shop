import 'package:product_shop/models/product.dart';
import 'package:product_shop/scoped-models/main.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class ProductFAB extends StatefulWidget {
  final Product product;
  ProductFAB(this.product);
  @override
  State<StatefulWidget> createState() {
    return _ProductFABState();
  }
}

class _ProductFABState extends State<ProductFAB> with TickerProviderStateMixin {
  AnimationController _controller;
  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant(
      builder: (BuildContext context, Widget child, MainModel model) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                height: 70,
                width: 56,
                //  FractionalOffset to make the parent widget take size of the child
                alignment: FractionalOffset.topCenter,
                child: ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _controller,
                        curve: Interval(0.0, 1.0, curve: Curves.easeOut)),
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).cardColor,
                      heroTag: 'contect',
                      mini: true,
                      onPressed: () async {
                        print(model.selectedProduct.userEmail);
                        final url = 'mailto:${model.selectedProduct.userEmail}';
                        // final url = 'mailto:pro.hussein.reda@gmail.com';
                        print(await canLaunch(url));
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'Could not launch';
                        }
                      },
                      child: Icon(
                        Icons.mail,
                        color: Theme.of(context).primaryColor,
                      ),
                    ))),
            Container(
                height: 70,
                width: 56,
                alignment: FractionalOffset.topCenter,
                child: ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _controller,
                        curve: Interval(0.0, 0.5, curve: Curves.easeOut)),
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).cardColor,
                      heroTag: 'options',
                      mini: true,
                      onPressed: () {
                        model.toggleProductFavoriteStatus(model.selectedProduct);
                      },
                      child: Icon(
                        model.selectedProduct.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ))),
            FloatingActionButton(
              onPressed: () {
                if (_controller.isDismissed) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              },
              // use AnimatedBuilder to detect another animation when it start or revers and
              // rebulid it's chlid
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget child) {
                  return Transform(
                      // FractionalOffset.center to make the icon rotat aroud center
                      alignment: FractionalOffset.center,
                      transform:
                          Matrix4.rotationZ(_controller.value * 0.5 * math.pi),
                      child: Icon(_controller.isDismissed
                          ? Icons.more_vert
                          : Icons.close));
                },
              ),
            )
          ],
        );
      },
    );
  }
}
