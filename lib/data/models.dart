class Session {
  const Session({required this.token, required this.username, this.refreshToken});

  final String token;
  final String username;
  final String? refreshToken;
}

class Product {
  const Product({required this.id, required this.title, required this.price, required this.category, required this.thumbnail});

  final int id;
  final String title;
  final double price;
  final String category;
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String? ?? 'Produit',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? 'general',
        thumbnail: json['thumbnail'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'price': price, 'category': category, 'thumbnail': thumbnail};
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.email, required this.image});

  final int id;
  final String name;
  final String email;
  final String image;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
        email: json['email'] as String? ?? '',
        image: json['image'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'firstName': name, 'email': email, 'image': image};
}

class Todo {
  const Todo({required this.id, required this.todo, required this.completed, required this.userId});

  final int id;
  final String todo;
  final bool completed;
  final int userId;

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as int,
        todo: json['todo'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        userId: json['userId'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'todo': todo, 'completed': completed, 'userId': userId};
}
