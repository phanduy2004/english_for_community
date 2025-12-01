class WritingEvent{

}
class GetWritingTopicsEvent extends WritingEvent{

}
class GetTopicHistoryEvent extends WritingEvent {
  final String topicId;
  GetTopicHistoryEvent(this.topicId);
}