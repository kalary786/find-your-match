import 'package:find_your_match/features/preview/preview_models.dart';

/// Fictional adults used only to lay out the interface.
/// Every record is marked [Person.isSample].
abstract final class MockPeople {
  static const mina = Person(
    id: 'sample_mina',
    username: 'sample_mina',
    displayName: 'Mina',
    age: 27,
    gender: 'Woman',
    city: 'Kochi',
    bio:
        'Sample bio. I spend weekends at the waterfront and cook for friends.',
    interests: ['Cooking', 'Travel', 'Coffee'],
    preferences: ['Dating', 'Long-term relationship'],
    hue: 12,
    isSample: true,
    online: true,
    verified: true,
  );

  static const arjun = Person(
    id: 'sample_arjun',
    username: 'sample_arjun',
    displayName: 'Arjun',
    age: 29,
    gender: 'Man',
    city: 'Bengaluru',
    bio: 'Sample bio. I read on the metro and look for hiking partners.',
    interests: ['Hiking', 'Reading', 'Music'],
    preferences: ['Friendship', 'Dating'],
    hue: 200,
    isSample: true,
    lastActive: 'Active yesterday',
  );

  static const sara = Person(
    id: 'sample_sara',
    username: 'sample_sara',
    displayName: 'Sara',
    age: 24,
    gender: 'Woman',
    city: 'Delhi',
    bio: 'Sample bio. Gallery walks and long playlists.',
    interests: ['Art', 'Music', 'Movies'],
    preferences: ['Dating'],
    hue: 330,
    isSample: true,
    likesYou: true,
    online: true,
  );

  static const omar = Person(
    id: 'sample_omar',
    username: 'sample_omar',
    displayName: 'Omar',
    age: 33,
    gender: 'Man',
    city: 'Hyderabad',
    bio: 'Sample bio. Amateur photographer and weekend cook.',
    interests: ['Photography', 'Cooking', 'Travel'],
    preferences: ['Long-term relationship', 'Marriage'],
    hue: 150,
    isSample: true,
    verified: true,
    lastActive: 'Active 3 days ago',
  );

  static const leila = Person(
    id: 'sample_leila',
    username: 'sample_leila',
    displayName: 'Leila',
    age: 26,
    gender: 'Woman',
    city: 'Mumbai',
    bio: 'Sample bio. Morning runs and neighborhood coffee.',
    interests: ['Fitness', 'Coffee', 'Movies'],
    preferences: ['Dating', 'Friendship'],
    hue: 28,
    isSample: true,
    likesYou: true,
    online: true,
    verified: true,
  );

  static const noah = Person(
    id: 'sample_noah',
    username: 'sample_noah',
    displayName: 'Noah',
    age: 31,
    gender: 'Man',
    city: 'Pune',
    bio: 'Sample bio. I like live music and slow Sundays.',
    interests: ['Music', 'Reading', 'Coffee'],
    preferences: ['Long-term relationship'],
    hue: 250,
    isSample: true,
    likesYou: true,
    lastActive: 'Active yesterday',
  );

  static const viewerStandIn = Person(
    id: 'sample_you',
    username: 'sample_you',
    displayName: 'Your preview',
    age: 28,
    gender: 'Prefer not to say',
    city: 'Your city',
    bio: 'Sample stand-in. Save a profile on this device to replace it.',
    interests: ['Coffee', 'Travel'],
    preferences: ['Dating'],
    hue: 8,
    isSample: true,
    hasPhoto: true,
  );

  static const catalog = [mina, arjun, sara, omar, leila, noah];

  static const presetLikedIds = {'sample_leila', 'sample_noah'};

  static Map<String, List<PreviewMessage>> initialMessages() {
    return {
      leila.id: const [
        PreviewMessage(
          id: 'm1',
          fromMe: false,
          text: 'Sample message: the Saturday market was crowded but fun.',
          timeLabel: 'Yesterday',
        ),
      ],
      noah.id: const [
        PreviewMessage(
          id: 'm2',
          fromMe: false,
          text: 'Sample message: there is a quiet set at the hall on Friday.',
          timeLabel: 'Mon',
        ),
      ],
    };
  }

  static Set<String> takenUsernames({String? except}) {
    return catalog
        .map((person) => person.username)
        .where((name) => name != except)
        .toSet();
  }
}
