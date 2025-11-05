class Product {
  final String name;
  final String category;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final bool isFavourite;
  final String description;
  const Product({
    required this.name,
    required this.category,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.isFavourite,
    required this.description,
  });
}
final List<Product> products = [
  const Product(
    name: 'Áo thun Basic',
    category: 'Áo quần',
    price: 199.000,
    oldPrice: 249.000,
    imageUrl: 'assets/images/ao_thun_basic.jpg',
    isFavourite: false,
    description: 'Áo thun cotton thoáng mát, form ôm vừa phải, phù hợp mặc hàng ngày.',
    
  ),
  const Product(
    name: 'Áo thun Basic',
    category: 'Áo quần',
    price: 199.000,
    oldPrice: 249.000,
    imageUrl: 'assets/images/ao_thun_basic.jpg',
    isFavourite: true,
    description: 'Áo thun cotton thoáng mát, form ôm vừa phải, phù hợp mặc hàng ngày.',
    
  ),
  const Product(
    name: 'Laptop',
    category: 'Laptop Asus X409JA',
    price: 1199.000,
    oldPrice: 1249.000,
    imageUrl: 'assets/images/laptop.jpg',
    isFavourite: true,
    description: 'Áo thun cotton thoáng mát, form ôm vừa phải, phù hợp mặc hàng ngày.',
    
  ),
  const Product(
    name: 'Áo thun Basic',
    category: 'Áo quần',
    price: 199.000,
    oldPrice: 249.000,
    imageUrl: 'assets/images/ao_thun_basic.jpg',
    isFavourite: false,
    description: 'Áo thun cotton thoáng mát, form ôm vừa phải, phù hợp mặc hàng ngày.',
    
  ),
  
];