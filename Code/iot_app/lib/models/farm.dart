import 'gateway.dart';

class Farm {
   String id;
   String name;
   String location;
   List<Gateway> gateways;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.gateways,
  });
}