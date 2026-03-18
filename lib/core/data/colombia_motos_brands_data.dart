abstract class ColombiaMotosBrandsData {
  static const List<String> brands = [
    // Líderes del mercado colombiano (2024)
    'AKT',
    'Yamaha',
    'Bajaj',
    'Suzuki',
    'Honda',
    'TVS',
    'Hero',
    'Royal Enfield',

    // Marcas internacionales premium
    'Kawasaki',
    'BMW Motorrad',
    'Ducati',
    'KTM',
    'Triumph',
    'Harley-Davidson',
    'Indian Motorcycle',
    'Aprilia',
    'Moto Guzzi',
    'MV Agusta',
    'Husqvarna',
    'Benelli',
    'CF Moto',
    'Royal Enfield',
    'Zero Motorcycles',

    // Marcas con distribución activa en Colombia
    'Kymco',
    'Zontes',
    'Voge',
    'Loncin',
    'Motrac',
    'Italika',
    'Zanella',
    'SYM',
    'Keeway',
    'Jialing',
    'Shineray',
    'Rieju',
    'Ural',
    'Kimco',
    'Skygo',
    'Pulsar', // línea Bajaj
    'UM Motorcycles',
    'Auteco', // distribuidor oficial de Kawasaki en Colombia
  ];

  static List<String> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return brands.where((b) => b.toLowerCase().contains(q)).take(8).toList();
  }
}
