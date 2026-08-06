enum AlarmSoundCategory { classical, soft }

class AlarmSound {
  final String id;
  final String label;
  final String assetPath;
  final AlarmSoundCategory category;

  const AlarmSound({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.category,
  });
}

/// Public-domain recordings (Wikimedia Commons) bundled under
/// assets/sounds/. See CREDITS in the repo for exact sources.
const alarmSoundCatalog = <AlarmSound>[
  AlarmSound(
    id: 'fur_elise',
    label: '엘리제를 위하여',
    assetPath: 'assets/sounds/classical_fur_elise.ogg',
    category: AlarmSoundCategory.classical,
  ),
  AlarmSound(
    id: 'air_g_string',
    label: 'G선상의 아리아',
    assetPath: 'assets/sounds/classical_air_g_string.ogg',
    category: AlarmSoundCategory.classical,
  ),
  AlarmSound(
    id: 'canon_d',
    label: '캐논 변주곡',
    assetPath: 'assets/sounds/classical_canon_d.wav',
    category: AlarmSoundCategory.classical,
  ),
  AlarmSound(
    id: 'soft_piano',
    label: '잔잔한 피아노',
    assetPath: 'assets/sounds/soft_piano.ogg',
    category: AlarmSoundCategory.soft,
  ),
  AlarmSound(
    id: 'soft_rain',
    label: '빗소리 차임',
    assetPath: 'assets/sounds/soft_rain.ogg',
    category: AlarmSoundCategory.soft,
  ),
  AlarmSound(
    id: 'soft_windchime',
    label: '산들바람',
    assetPath: 'assets/sounds/soft_windchime.ogg',
    category: AlarmSoundCategory.soft,
  ),
];

AlarmSound alarmSoundById(String id) =>
    alarmSoundCatalog.firstWhere((s) => s.id == id, orElse: () => alarmSoundCatalog.first);
