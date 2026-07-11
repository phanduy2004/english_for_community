abstract class AdminAnalyticsEvent {}

class AdminAnalyticsLoadRequested extends AdminAnalyticsEvent {
  AdminAnalyticsLoadRequested({this.range = 'week'});

  final String range;
}

class AdminAnalyticsRangeChanged extends AdminAnalyticsEvent {
  AdminAnalyticsRangeChanged(this.range);

  final String range;
}
