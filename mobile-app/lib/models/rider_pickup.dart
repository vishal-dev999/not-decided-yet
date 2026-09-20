class RiderPickupMaterial {
  final String name;
  final String quantity;

  const RiderPickupMaterial({
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory RiderPickupMaterial.fromMap(
    Map<String, dynamic> map,
  ) {
    return RiderPickupMaterial(
      name: map['name']?.toString() ?? '',
      quantity: map['quantity']?.toString() ?? '',
    );
  }
}

class RiderPickup {
  final String id;
  final String name;
  final String person;
  final String? phone;
  final String location;
  final String address;
  final String distance;
  final String time;
  final String status;
  final String expectedMaterial;
  final List<RiderPickupMaterial> expectedMaterials;

  const RiderPickup({
    required this.id,
    required this.name,
    required this.person,
    this.phone,
    required this.location,
    required this.address,
    required this.distance,
    required this.time,
    required this.status,
    required this.expectedMaterial,
    this.expectedMaterials = const [],
  });

  bool get isCompleted => status == 'completed';

  String get pickupId => id;

  RiderPickup copyWith({
    String? id,
    String? name,
    String? person,
    String? phone,
    String? location,
    String? address,
    String? distance,
    String? time,
    String? status,
    String? expectedMaterial,
    List<RiderPickupMaterial>? expectedMaterials,
  }) {
    return RiderPickup(
      id: id ?? this.id,
      name: name ?? this.name,
      person: person ?? this.person,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      status: status ?? this.status,
      expectedMaterial:
          expectedMaterial ?? this.expectedMaterial,
      expectedMaterials:
          expectedMaterials ?? this.expectedMaterials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'person': person,
      'phone': phone,
      'location': location,
      'address': address,
      'distance': distance,
      'time': time,
      'status': status,
      'expectedMaterial': expectedMaterial,
      'expectedMaterials':
          expectedMaterials.map((item) => item.toMap()).toList(),
    };
  }

  factory RiderPickup.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawMaterials = map['expectedMaterials'];

    final materials = <RiderPickupMaterial>[];

    if (rawMaterials is List) {
      for (final item in rawMaterials) {
        if (item is Map) {
          materials.add(
            RiderPickupMaterial.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return RiderPickup(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      person: map['person']?.toString() ?? '',
      phone: map['phone']?.toString(),
      location: map['location']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      distance: map['distance']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      status: map['status']?.toString() ?? 'assigned',
      expectedMaterial:
          map['expectedMaterial']?.toString() ?? 'E-waste',
      expectedMaterials: materials,
    );
  }

  /// Current Section 5 assigned pickups.
  ///
  /// Each pickup has its own permanent ID.
  static const List<RiderPickup> assignedPickups = [
    RiderPickup(
      id: 'pickup_001',
      name: 'Sharma Scrap Centre',
      person: 'Rajesh Sharma',
      phone: '+91 98765 43210',
      location: 'Bhubaneswar',
      address: 'Saheed Nagar, Bhubaneswar',
      distance: '2.4 km',
      time: '09:30 AM',
      status: 'assigned',
      expectedMaterial: '50+ items',
      expectedMaterials: [
        RiderPickupMaterial(
          name: 'Computers / Laptops',
          quantity: '12 items',
        ),
        RiderPickupMaterial(
          name: 'Mobile phones',
          quantity: '18 items',
        ),
        RiderPickupMaterial(
          name: 'Other electronics',
          quantity: 'Approx. 25 kg',
        ),
      ],
    ),

    RiderPickup(
      id: 'pickup_002',
      name: 'Kumar Kabadi',
      person: 'Suresh Kumar',
      phone: null,
      location: 'Patia',
      address: 'Patia, Bhubaneswar',
      distance: '5.8 km',
      time: '11:15 AM',
      status: 'assigned',
      expectedMaterial: 'E-waste',
    ),

    RiderPickup(
      id: 'pickup_003',
      name: 'Verma Scrap & E-Waste',
      person: 'Amit Verma',
      phone: null,
      location: 'Khandagiri',
      address: 'Khandagiri, Bhubaneswar',
      distance: '8.1 km',
      time: '02:30 PM',
      status: 'assigned',
      expectedMaterial: 'E-waste',
    ),
  ];
}