import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Web storage using SharedPreferences
  static const String _postsKey = 'offline_posts';
  List<Post> _cachedPosts = [];
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> _init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadPosts();
    _isInitialized = true;
  }

  Future<void> _loadPosts() async {
    final String? postsJson = _prefs!.getString(_postsKey);
    if (postsJson != null) {
      final List<dynamic> postsList = json.decode(postsJson);
      _cachedPosts = postsList.map((json) => Post.fromJson(json)).toList();
    } else {
      _cachedPosts = [];
    }
  }

  Future<void> _savePosts() async {
    final String postsJson = json.encode(
      _cachedPosts.map((post) => post.toJson()).toList()
    );
    await _prefs!.setString(_postsKey, postsJson);
  }

  // Create - Add new post
  Future<int> insertPost(Post post) async {
    await _init();
    
    final newId = _cachedPosts.isEmpty ? 1 : (_cachedPosts.map((p) => p.id!).reduce((a, b) => a > b ? a : b) + 1);
    final newPost = post.copyWith(id: newId);
    _cachedPosts.insert(0, newPost);
    await _savePosts();
    return newId;
  }

  // Read - Get all posts
  Future<List<Post>> getAllPosts() async {
    await _init();
    return _cachedPosts;
  }

  // Read - Get single post
  Future<Post?> getPost(int id) async {
    await _init();
    try {
      return _cachedPosts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update - Edit existing post
  Future<int> updatePost(Post post) async {
    await _init();
    
    final index = _cachedPosts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _cachedPosts[index] = post;
      await _savePosts();
      return 1;
    }
    return 0;
  }

  // Delete - Remove post
  Future<int> deletePost(int id) async {
    await _init();
    
    _cachedPosts.removeWhere((post) => post.id == id);
    await _savePosts();
    return 1;
  }

  // Search posts
  Future<List<Post>> searchPosts(String query) async {
    await _init();
    
    if (query.isEmpty) return _cachedPosts;
    
    return _cachedPosts.where((post) =>
      post.title.toLowerCase().contains(query.toLowerCase()) ||
      post.content.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get post count
  Future<int> getPostCount() async {
    await _init();
    return _cachedPosts.length;
  }

  // Delete all posts
  Future<void> deleteAllPosts() async {
    await _init();
    _cachedPosts.clear();
    await _savePosts();
  }
}