import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:product_shop/models/location_data.dart';
import 'package:product_shop/models/product.dart';
import 'package:product_shop/models/user.dart';
// import 'package:http_parser/http_parser.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:product_shop/models/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';
// import 'package:mime/mime.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;

  Future<Null> fetchProducts({onlyForUser = false, clearExisting = false}) {
    _isLoading = true;
    if (clearExisting) {
      _products = [];
    }
    notifyListeners();
    return http
        .get(
            'https://flutterapp-5341d.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      final List<Product> fetchedProductList = [];
      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      productListData.forEach((String productid, dynamic productData) {
        final Product product = Product(
            id: productid,
            title: productData['title'],
            description: productData['description'],
            imagePath: productData['imagePath'],
            image: productData['imageUrl'],
            price: productData['price'],
            location: LocationData(
                address: productData['loc_address'],
                latitude: productData['loc_lat'],
                longitude: productData['loc_lng']),
            userEmail: productData['userEmail'],
            userId: productData['userId'],
            isFavorite: productData['wishlistUsers'] == null
                ? false
                : (productData['wishlistUsers'] as Map<String, dynamic>)
                    .containsKey(_authenticatedUser.id));
        fetchedProductList.add(product);
      });
      _products = onlyForUser
          ? fetchedProductList.where((Product product) {
              return product.userId == _authenticatedUser.id;
            }).toList()
          : fetchedProductList;
      _isLoading = false;
      notifyListeners();
      _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }
}

mixin ProductModel on ConnectedProductsModel {
  bool _showFavorites = false;
  List<Product> get allProducts {
    // List form copy our list
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (_showFavorites) {
      return _products.where((Product product) => product.isFavorite).toList();
    }
    return List.from(_products);
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  bool get showFavorits {
    return _showFavorites;
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadImage(File image) async {
    String path = "images/" + image.path.split('/')[image.path.split('/').length -1];
        print(path);

    final StorageReference storageReference =
        FirebaseStorage().ref().child(path);
    final StorageUploadTask uploadTask =
        storageReference.putData(await image.readAsBytes());
    var value = await (await uploadTask.onComplete).ref.getDownloadURL();
    var url = value.toString();
    print(path);
    print(url);
    var ruslt = {'imagePath': path, 'imageUrl': url};
    return ruslt;
  }

  // Future<Map<String, dynamic>> uploadImage(File image,
  //     {String imagePath}) async {
  //   final mimeTypeData = lookupMimeType(image.path).split('/');
  //   final imageUploadRequest = http.MultipartRequest(
  //       'POST',
  //       Uri.parse(
  //           'https://us-central1-flutterapp-5341d.cloudfunctions.net/storeImage'));
  //   final file = await http.MultipartFile.fromPath('image', image.path,
  //       contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
  //   imageUploadRequest.files.add(file);
  //   if (imagePath != null) {
  //     imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
  //   }
  //   imageUploadRequest.headers['Authorization'] =
  //       'Bearer ${_authenticatedUser.token}';
  //   imageUploadRequest.headers['Content-Type'] = 'application/json';
  //   try {
  //     final streamedResponse = await imageUploadRequest.send();
  //     print(streamedResponse.statusCode);
  //     print(streamedResponse.reasonPhrase);
  //     print("********************************");
  //     print(MediaType(mimeTypeData[0], mimeTypeData[1]));
  //     final response = await http.Response.fromStream(streamedResponse);
  //     print("********************************");
  //     print(response.body);
  //     print("********************************");

  //     if (response.statusCode != 200 && response.statusCode != 201) {
  //       return null;
  //     }
  //     final responseData = json.decode(response.body);
  //     return responseData;
  //   } catch (error) {
  //     print(error);
  //     return null;
  //   }
  // }

  Future<bool> addProduct(String title, String description, File image,
      double price, LocationData locData) async {
    _isLoading = true;
    notifyListeners();
    final uploadData = await uploadImage(image);
    if (uploadData == null) {
      return false;
    }

    Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address
    };
    try {
      final http.Response response = await http.post(
          'https://flutterapp-5341d.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
          body: json.encode(productData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      Product newProduct = Product(
          id: responseData['name'],
          title: title,
          description: description,
          image: uploadData['imageUrl'],
          imagePath: uploadData['imagePath'],
          price: price,
          location: locData,
          userEmail: _authenticatedUser.email,
          userId: _authenticatedUser.id);
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String title, String description, File image,
      double price, LocationData locData) async {
    _isLoading = true;
    notifyListeners();
    String imageUrl = selectedProduct.image;
    String imagePath = selectedProduct.imagePath;
    if (image != null) {
      final uploadData = await uploadImage(image);
      if (uploadData == null) {
        return false;
      }
      imageUrl = uploadData['imageUrl'];
      imagePath = uploadData['imagePath'];
    }
    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id
    };
    try {
      await http.put(
          'https://flutterapp-5341d.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(updateData));

      _isLoading = false;
      notifyListeners();
      Product updatedProduct = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          image: imageUrl,
          imagePath: imagePath,
          price: price,
          location: locData,
          userEmail: selectedProduct.userEmail,
          userId: selectedProduct.userId);
      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final deletedID = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();
    return http
        .delete(
            'https://flutterapp-5341d.firebaseio.com/products/$deletedID.json?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleProductFavoriteStatus(Product toggledProduct) async {
    final bool isCurrentFavorite = toggledProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentFavorite;
    final int toggledProductIndex = _products.indexWhere((Product product) {
      return product.id == toggledProduct.id;
    });
    final Product updatedProduct = Product(
        id: toggledProduct.id,
        title: toggledProduct.title,
        price: toggledProduct.price,
        image: toggledProduct.image,
        imagePath: toggledProduct.imagePath,
        location: toggledProduct.location,
        description: toggledProduct.description,
        userEmail: toggledProduct.userEmail,
        userId: toggledProduct.userId,
        isFavorite: newFavoriteStatus);
    _products[toggledProductIndex] = updatedProduct;
    notifyListeners();
    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
          'https://flutterapp-5341d.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(true));
    } else {
      response = await http.delete(
          'https://flutterapp-5341d.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final Product updatedProduct = Product(
          id: toggledProduct.id,
          title: toggledProduct.title,
          price: toggledProduct.price,
          image: toggledProduct.image,
          imagePath: toggledProduct.imagePath,
          location: toggledProduct.location,
          description: toggledProduct.description,
          userEmail: toggledProduct.userEmail,
          userId: toggledProduct.userId,
          isFavorite: !newFavoriteStatus);
      _products[toggledProductIndex] = updatedProduct;
      notifyListeners();
    }
    // _selProductId = null;
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

mixin UserModel on ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();
  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(
      String email, String password, authMode) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
    http.Response response;
    if (authMode == AuthMode.Login) {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyB_fa_X1aU8O-jX5EcsiMMicAF2Svui67U',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    } else if (authMode == AuthMode.Signup) {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyB_fa_X1aU8O-jX5EcsiMMicAF2Svui67U',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    }
    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasEror = true;
    String message = 'somthing went worng.';
    if (responseData.containsKey("idToken")) {
      hasEror = false;
      message = 'Authentication succeed.';
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This Email wasn\'t found';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'INVALID PASSWORD';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This Email Alredy Exist';
    }
    _isLoading = false;
    notifyListeners();
    _authenticatedUser = User(
        id: responseData['localId'],
        email: email,
        token: responseData['idToken']);
    setAuthTimeout(int.parse(responseData['expiresIn']));
    final DateTime now = DateTime.now();
    final DateTime expiryTime =
        now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
    _userSubject.add(true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('token', responseData['idToken']);
    prefs.setString('userEmail', email);
    prefs.setString('userId', responseData['localId']);
    prefs.setString('expiryTime', expiryTime.toIso8601String());
    return {'success': !hasEror, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedexpiryTime = DateTime.parse(expiryTimeString);
      if (parsedexpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString("userEmail");
      final String userId = prefs.getString("userId");
      final int tokenLifeSpan = parsedexpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifeSpan);
      notifyListeners();
    }
  }

  void logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    _selProductId = null;
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}
mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
