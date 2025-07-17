class MaterialHierarchy {
  final String id;
  final String name;
  final String category;
  final List<ComponentMaterial> components;
  final Map<String, dynamic> specifications;

  MaterialHierarchy({
    required this.id,
    required this.name,
    required this.category,
    required this.components,
    required this.specifications,
  });
}

class ComponentMaterial {
  final String materialId;
  final String materialName;
  final double quantity;
  final String unit;
  final String size;
  final bool isOptional;

  ComponentMaterial({
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.size,
    this.isOptional = false,
  });
}

// Predefined material hierarchies
class WaterSystemMaterials {
  static final Map<String, MaterialHierarchy> hierarchies = {
    'zadvizhka_300': MaterialHierarchy(
      id: 'zadvizhka_300',
      name: 'Задвижка Ø300мм',
      category: 'Запорная арматура',
      specifications: {
        'diameter': '300мм',
        'pressure': '16 атм',
        'material': 'Чугун',
      },
      components: [
        ComponentMaterial(
          materialId: 'bolt_m16_80',
          materialName: 'Болт М16х80',
          quantity: 8,
          unit: 'дона',
          size: 'М16х80',
        ),
        ComponentMaterial(
          materialId: 'nut_m16',
          materialName: 'Гайка М16',
          quantity: 8,
          unit: 'дона',
          size: 'М16',
        ),
        ComponentMaterial(
          materialId: 'washer_16',
          materialName: 'Шайба 16',
          quantity: 16,
          unit: 'дона',
          size: '16мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_300',
          materialName: 'Прокладка резиновая',
          quantity: 2,
          unit: 'дона',
          size: 'Ø300мм',
        ),
        ComponentMaterial(
          materialId: 'grease',
          materialName: 'Смазка техническая',
          quantity: 0.2,
          unit: 'кг',
          size: '',
        ),
      ],
    ),
    
    'mufta_fla_300': MaterialHierarchy(
      id: 'mufta_fla_300',
      name: 'Муфта фла. Ø300мм',
      category: 'Соединительные детали',
      specifications: {
        'diameter': '300мм',
        'type': 'Фланцевая',
        'material': 'Чугун',
      },
      components: [
        ComponentMaterial(
          materialId: 'bolt_m16_60',
          materialName: 'Болт М16х60',
          quantity: 12,
          unit: 'дона',
          size: 'М16х60',
        ),
        ComponentMaterial(
          materialId: 'nut_m16',
          materialName: 'Гайка М16',
          quantity: 12,
          unit: 'дона',
          size: 'М16',
        ),
        ComponentMaterial(
          materialId: 'washer_16',
          materialName: 'Шайба 16',
          quantity: 24,
          unit: 'дона',
          size: '16мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_300_fla',
          materialName: 'Прокладка фланцевая',
          quantity: 2,
          unit: 'дона',
          size: 'Ø300мм',
        ),
      ],
    ),

    'troynik_300x300': MaterialHierarchy(
      id: 'troynik_300x300',
      name: 'Тройник Ø300x300мм',
      category: 'Фасонные части',
      specifications: {
        'mainDiameter': '300мм',
        'branchDiameter': '300мм',
        'angle': '90°',
        'material': 'Чугун',
      },
      components: [
        ComponentMaterial(
          materialId: 'bolt_m16_70',
          materialName: 'Болт М16х70',
          quantity: 18,
          unit: 'дона',
          size: 'М16х70',
        ),
        ComponentMaterial(
          materialId: 'nut_m16',
          materialName: 'Гайка М16',
          quantity: 18,
          unit: 'дона',
          size: 'М16',
        ),
        ComponentMaterial(
          materialId: 'washer_16',
          materialName: 'Шайба 16',
          quantity: 36,
          unit: 'дона',
          size: '16мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_300_fla',
          materialName: 'Прокладка фланцевая',
          quantity: 3,
          unit: 'дона',
          size: 'Ø300мм',
        ),
      ],
    ),
  };
}

// Kolodets materials hierarchies
class KolodtsMaterials {
  static final Map<String, MaterialHierarchy> hierarchies = {
    'kolodts_ring_ks10': MaterialHierarchy(
      id: 'kolodts_ring_ks10',
      name: 'Железобетонные кольца КС-10',
      category: 'Конструктивные элементы',
      specifications: {
        'diameter': '1000мм',
        'height': '890мм',
        'weight': '460кг',
        'material': 'Железобетон',
      },
      components: [
        ComponentMaterial(
          materialId: 'concrete_m200',
          materialName: 'Бетон М200',
          quantity: 0.23,
          unit: 'м³',
          size: '',
        ),
        ComponentMaterial(
          materialId: 'rebar_a3_8',
          materialName: 'Арматура А-III Ø8',
          quantity: 15,
          unit: 'кг',
          size: 'Ø8мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_rubber',
          materialName: 'Прокладка резиновая',
          quantity: 1,
          unit: 'дона',
          size: 'Ø1000мм',
        ),
      ],
    ),
    
    'kolodts_ring_ks15': MaterialHierarchy(
      id: 'kolodts_ring_ks15',
      name: 'Железобетонные кольца КС-15',
      category: 'Конструктивные элементы',
      specifications: {
        'diameter': '1500мм',
        'height': '890мм',
        'weight': '680кг',
        'material': 'Железобетон',
      },
      components: [
        ComponentMaterial(
          materialId: 'concrete_m200',
          materialName: 'Бетон М200',
          quantity: 0.34,
          unit: 'м³',
          size: '',
        ),
        ComponentMaterial(
          materialId: 'rebar_a3_10',
          materialName: 'Арматура А-III Ø10',
          quantity: 22,
          unit: 'кг',
          size: 'Ø10мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_rubber',
          materialName: 'Прокладка резиновая',
          quantity: 1,
          unit: 'дона',
          size: 'Ø1500мм',
        ),
      ],
    ),
    
    'kolodts_ring_ks20': MaterialHierarchy(
      id: 'kolodts_ring_ks20',
      name: 'Железобетонные кольца КС-20',
      category: 'Конструктивные элементы',
      specifications: {
        'diameter': '2000мм',
        'height': '890мм',
        'weight': '920кг',
        'material': 'Железобетон',
      },
      components: [
        ComponentMaterial(
          materialId: 'concrete_m200',
          materialName: 'Бетон М200',
          quantity: 0.46,
          unit: 'м³',
          size: '',
        ),
        ComponentMaterial(
          materialId: 'rebar_a3_12',
          materialName: 'Арматура А-III Ø12',
          quantity: 28,
          unit: 'кг',
          size: 'Ø12мм',
        ),
        ComponentMaterial(
          materialId: 'gasket_rubber',
          materialName: 'Прокладка резиновая',
          quantity: 1,
          unit: 'дона',
          size: 'Ø2000мм',
        ),
      ],
    ),
    
    'submersible_pump': MaterialHierarchy(
      id: 'submersible_pump',
      name: 'Погружной насос вибрационный',
      category: 'Насосное оборудование',
      specifications: {
        'power': '280Вт',
        'flow': '1200л/ч',
        'head': '60м',
        'diameter': '100мм',
      },
      components: [
        ComponentMaterial(
          materialId: 'cable_submersible',
          materialName: 'Кабель погружной',
          quantity: 25,
          unit: 'м',
          size: '3x1.5мм²',
        ),
        ComponentMaterial(
          materialId: 'rope_safety',
          materialName: 'Трос страховочный',
          quantity: 25,
          unit: 'м',
          size: 'Ø3мм',
        ),
        ComponentMaterial(
          materialId: 'clamp_cable',
          materialName: 'Хомут кабельный',
          quantity: 10,
          unit: 'дона',
          size: '',
        ),
      ],
    ),
    
    'cast_iron_hatch': MaterialHierarchy(
      id: 'cast_iron_hatch',
      name: 'Люк чугунный',
      category: 'Запорная арматура',
      specifications: {
        'diameter': '700мм',
        'material': 'Чугун',
      },
      components: [
        ComponentMaterial(
          materialId: 'cast_iron',
          materialName: 'Чугун',
          quantity: 0.1,
          unit: 'м³',
          size: '',
        ),
        ComponentMaterial(
          materialId: 'paint',
          materialName: 'Краска эмалировочная',
          quantity: 0.5,
          unit: 'л',
          size: '',
        ),
        ComponentMaterial(
          materialId: 'screws',
          materialName: 'Шурупы',
          quantity: 50,
          unit: 'шт',
          size: 'М10х30',
        ),
      ],
    ),
  };
}
