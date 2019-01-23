import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logintest/modal/api.dart';
import 'package:logintest/modal/keranjangModel.dart';
import 'package:logintest/modal/produkModel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuUsers extends StatefulWidget {
  final VoidCallback signOut;
  MenuUsers(this.signOut);
  @override
  _MenuUsersState createState() => _MenuUsersState();
}

class _MenuUsersState extends State<MenuUsers> {
  final money = NumberFormat("#,##0", "en_US");

  String idUsers;

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      idUsers = preferences.getString("id");
    });
    _lihatData();
  }

  var loading = false;
  final list = new List<ProdukModel>();
  final GlobalKey<RefreshIndicatorState> _refresh =
      GlobalKey<RefreshIndicatorState>();
  Future<void> _lihatData() async {
    list.clear();
    setState(() {
      loading = true;
    });
    final response = await http.get(BaseUrl.lihatProduk);
    if (response.contentLength == 2) {
    } else {
      final data = jsonDecode(response.body);
      data.forEach((api) {
        final ab = new ProdukModel(
          api['id'],
          api['namaProduk'],
          api['qty'],
          api['harga'],
          api['createdDate'],
          api['idUsers'],
          api['nama'],
          api['image'],
        );
        list.add(ab);
      });
      setState(() {
        _jumlahKeranjang();
        loading = false;
      });
    }
  }

  tambahKeranjang(String idProduk, String harga) async {
    final response = await http.post(BaseUrl.tambahKeranjang, body: {
      "idUsers": idUsers,
      "idProduk": idProduk,
      "harga": harga,
    });
    final data = jsonDecode(response.body);
    int value = data['value'];
    String pesan = data['message'];
    if (value == 1) {
      print(pesan);
      _jumlahKeranjang();
    } else {
      print(pesan);
    }
  }

  String jumlah = "0";
  final ex = List<KeranjangModel>();
  _jumlahKeranjang() async {
    setState(() {
      loading = true;
    });
    ex.clear();
    final response = await http.get(BaseUrl.jumlahKeranjang + idUsers);
    final data = jsonDecode(response.body);
    data.forEach((api) {
      final exp = new KeranjangModel(api['jumlah']);
      ex.add(exp);
      setState(() {
        jumlah = exp.jumlah;
      });
    });
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Stack(
            children: <Widget>[
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.shopping_cart),
              ),
              jumlah == "0"
                  ? Container()
                  : Positioned(
                      right: 0.0,
                      child: Stack(
                        children: <Widget>[
                          Icon(
                            Icons.brightness_1,
                            size: 25.0,
                            color: Colors.orange,
                          ),
                          Positioned(
                            top: 4.0,
                            right: 6.0,
                            child: Text(
                              jumlah,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11.0),
                            ),
                          )
                        ],
                      ),
                    )
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                widget.signOut();
              });
            },
            icon: Icon(Icons.lock_open),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refresh,
        onRefresh: _lihatData,
        child: Container(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final x = list[i];
                  return Card(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Image.network(
                            'http://192.168.1.100/login/upload/' + x.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          x.namaProduk,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Rp. " + money.format(int.parse(x.harga)),
                          style: TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                        RaisedButton(
                          onPressed: () {
                            tambahKeranjang(x.id, x.harga);
                          },
                          color: Colors.orange,
                          child: Text(
                            "Beli",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
