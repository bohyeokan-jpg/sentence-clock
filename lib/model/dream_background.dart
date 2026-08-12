enum DreamBackgroundId { none, ocean, space, sky, beach }

class DreamBackgroundOption {
  final DreamBackgroundId id;
  final String label;

  const DreamBackgroundOption({required this.id, required this.label});
}

const dreamBackgroundOptions = <DreamBackgroundId, DreamBackgroundOption>{
  DreamBackgroundId.none: DreamBackgroundOption(id: DreamBackgroundId.none, label: '없음'),
  DreamBackgroundId.ocean: DreamBackgroundOption(id: DreamBackgroundId.ocean, label: '파도'),
  DreamBackgroundId.space: DreamBackgroundOption(id: DreamBackgroundId.space, label: '우주'),
  DreamBackgroundId.sky: DreamBackgroundOption(id: DreamBackgroundId.sky, label: '맑은 하늘'),
  DreamBackgroundId.beach: DreamBackgroundOption(id: DreamBackgroundId.beach, label: '해변'),
};
