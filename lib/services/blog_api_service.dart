import 'dart:convert';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/blog.dart';

class BlogApiService {
  /// Fetch all published blog posts
  Future<List<BlogItem>> fetchBlogs({String? section}) async {
    try {
      String url = '${GlobalVariables.reviewsServiceUrl}api/blogs/';
      if (section != null) {
        url += '?section=$section';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? data;

        return results
            .map((json) => BlogItem.fromJson(_formatBlogJson(json)))
            .toList();
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blogs: $e');
    }
  }

  /// Fetch a specific blog post with comments
  Future<BlogItem> fetchBlogById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.reviewsServiceUrl}api/blogs/$id/'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BlogItem.fromJson(_formatBlogJson(json));
      } else {
        throw Exception('Failed to load blog: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blog: $e');
    }
  }

  /// Fetch comments for a specific blog post
  Future<List<BlogComment>> fetchBlogComments(int blogId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.reviewsServiceUrl}api/blogs/$blogId/comments/',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => BlogComment.fromJson(_formatCommentJson(json)))
            .toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  /// Increment view count for a blog post
  Future<void> incrementBlogViews(int blogId) async {
    try {
      await http.post(
        Uri.parse(
          '${GlobalVariables.reviewsServiceUrl}api/blogs/$blogId/increment_views/',
        ),
      );
    } catch (e) {
      // Silently fail - not critical
      print('Failed to increment views: $e');
    }
  }

  /// Like/unlike a blog post
  Future<Map<String, dynamic>> toggleBlogLike(int blogId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.reviewsServiceUrl}api/blogs/$blogId/toggle_like/',
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  /// Format backend blog JSON to match Flutter model expectations
  Map<String, dynamic> _formatBlogJson(Map<String, dynamic> json) {
    // Parse tags string to list
    List<String> tagsList = [];
    if (json['tags'] != null && json['tags'].isNotEmpty) {
      tagsList = json['tags']
          .toString()
          .split(',')
          .map((tag) => tag.trim())
          .toList();
    }

    // Get section display name
    String sectionDisplay = _getSectionDisplayName(json['section'] ?? '');

    // Format author data
    Map<String, dynamic>? author;
    if (json['author'] != null) {
      author = {
        'id': json['author']['id'],
        'username': json['author']['username'],
        'first_name': json['author']['first_name'],
        'last_name': json['author']['last_name'],
      };
    }

    // Get comments count from comments array or separate field
    int commentsCount = json['comments_count'] ?? 0;
    if (json['comments'] != null) {
      commentsCount = (json['comments'] as List).length;
    }

    return {
      'id': json['id'],
      'title': json['title'],
      'description': json['description'],
      'content': json['content'],
      'image': json['image_url'] ?? json['image'],
      'section': json['section'],
      'section_display': sectionDisplay,
      'author': author,
      'tags_list': tagsList,
      'likes': json['likes'] ?? 0,
      'views': json['views'] ?? 0,
      'comments_count': commentsCount,
      'created_at': json['created_at'],
      'published_at': json['published_at'],
      'comments': json['comments']
          ?.map((comment) => _formatCommentJson(comment))
          .toList(),
    };
  }

  /// Format backend comment JSON to match Flutter model expectations
  Map<String, dynamic> _formatCommentJson(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'user': {
        'id': json['user']['id'],
        'username': json['user']['username'],
        'first_name': json['user']['first_name'],
        'last_name': json['user']['last_name'],
      },
      'content': json['content'],
      'is_approved': json['is_approved'] ?? true,
      'created_at': json['created_at'],
    };
  }

  /// Get display name for blog section
  String _getSectionDisplayName(String section) {
    const sectionMap = {
      'auto_transport': 'Auto & Transport',
      'electronics': 'Electronics',
      'marketplace_tips': 'Marketplace Tips',
      'company_news': 'Company News',
    };
    return sectionMap[section] ?? section;
  }

  /// Get available blog sections
  static const Map<String, String> blogSections = {
    'auto_transport': 'Auto & Transport',
    'electronics': 'Electronics',
    'marketplace_tips': 'Marketplace Tips',
    'company_news': 'Company News',
  };
}
