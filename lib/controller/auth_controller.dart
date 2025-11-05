import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController{
  final _storage = GetStorage();

  final RxBool _isFirstime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  bool get isFirstime => _isFirstime.value;
  bool get isLoggedIn => _isLoggedIn.value;

  @override
  void onInit() {
    super.onInit();
    _loadInitialStates();
  }

  void _loadInitialStates() {
    _isFirstime.value = _storage.read('isFirstime') ?? true;
    _isLoggedIn.value = _storage.read('isLoggedIn') ?? false;
  }
  void setFirstime() {
    _isFirstime.value = false;
    _storage.write('isFirstime', false);
  }
  void login(){
    _isLoggedIn.value = true;
    _storage.write('isLoggedIn', true);
  }
  void logout(){
    _isLoggedIn.value = false;
    _storage.write('isLoggedIn', false);
  }
}