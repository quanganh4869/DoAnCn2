import 'package:ecomerceapp/models/user_profile.dart';
import 'package:ecomerceapp/seller_dasboard/model/seller.dart'; 

class SellerRequest {
  final Seller seller;
  final UserProfile user;

  SellerRequest({required this.seller, required this.user});

  factory SellerRequest.fromSupabaseJson(Map<String, dynamic> json) {
    return SellerRequest(
      // Parse thông tin Seller
      seller: Seller.fromJson(json),
      // Parse thông tin User (Do dùng .select('*, users(*)') nên data user nằm trong key 'users')
      user: UserProfile.fromJson(json['users'] ?? {}),
    );
  }
}