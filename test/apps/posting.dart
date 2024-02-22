import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Post with ChangeNotifier {
  int id;
  String title;
  String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class PostService with ChangeNotifier {
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      final List<dynamic> responseData = json.decode(response.body);
      final List<Post> fetchedPosts = responseData.map((post) => Post.fromJson(post)).toList();

      _posts = fetchedPosts;

      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    }
  }
}

class MyHomePage1 extends StatelessWidget {
  const MyHomePage1({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = Provider.of<PostService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: ListView.builder(
        itemCount: postService.posts.length,
        itemBuilder: (context, index) {
          final post = postService.posts[index];
          return ListTile(
            title: Text(post.title),
            subtitle: Text(post.body),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          postService.fetchPosts();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (context) => PostViewModel(),
        child: const MyHomePage(),
      ),
    );
  }
  
}

abstract class BaseRepository<T> {
  Future<T> fetch();
}

abstract class BaseViewModel<T> with ChangeNotifier {
  final BaseRepository<T> repository;
  T? _data;

  BaseViewModel(this.repository);

  T? get data => _data;

  Future<void> fetchData() async {
    _data = await repository.fetch();
    notifyListeners();
  }
}

class PostRepository extends BaseRepository<Post> {
  var rnd = Random(DateTime.now().millisecondsSinceEpoch);
  
  @override
  Future<Post> fetch() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts/${1+rnd.nextInt(100)}'));
    final responseData = json.decode(response.body);
    return Post(
      id: responseData['id'],
      title: responseData['title'],
      body: responseData['body'],
    );
  }
}

class PostViewModel extends BaseViewModel<Post> {
  PostViewModel() : super(PostRepository());
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posting'),
      ),
      body: Center(
        child: Consumer<PostViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.data == null) {
              return const CircularProgressIndicator();
            } else {
              final post = viewModel.data;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${post!.id}'),
                  const SizedBox(height: 8),
                  Text(post.title),
                  const SizedBox(height: 8),
                  Text(post.body),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<PostViewModel>(context, listen: false).fetchData();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}