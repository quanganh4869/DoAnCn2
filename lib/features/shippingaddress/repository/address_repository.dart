import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

class AddressRepository {
  List<Address> getAddresses() {
    return const[
      Address(
        id: "1",
        label: 'Home',
        fullAddress: '123 Main St, Springfield, IL, 62701',
        city: 'Springfield',
        state: 'IL',
        zipCode: '62701',
        isDefault: true,
        type: AddressType.home,
      ),
      Address(
        id: "2",
        label: 'Office',
        fullAddress: '456 Corporate Blvd, Metropolis, NY, 10001',
        city: 'Metropolis',
        state: 'NY',
        zipCode: '10001',
        type: AddressType.office,
      ),
      Address(
        id: "3",
        label: 'Other',
        fullAddress: '789 Elm St, Gotham, NJ, 07097',
        city: 'Gotham',
        state: 'NJ',
        zipCode: '07097',
        type: AddressType.other,
      ),
    ];
  }
  Address? getDefaultAddress() {
    return getAddresses().firstWhere((address) => address.isDefault, orElse: () => getAddresses().first);
  }
}