import 'gateway.dart';

class Farm {
   String id;
   String name;
   String location;
   List<Gateway> gateways; // 🔥 thêm dòng này

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.gateways,
  });
}