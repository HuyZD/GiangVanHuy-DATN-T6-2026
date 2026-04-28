import 'node.dart';

class Gateway {
   String id;
   String name;
   String status;
   List<Node> nodes;

  Gateway({
    required this.id,
    required this.name,
    required this.status,
    required this.nodes,
  });
}