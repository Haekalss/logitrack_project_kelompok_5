import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:p1/delivery_task_model.dart';

class ApiService {
  // URL endpoint dari API
  final String apiUrl = "https://jsonplaceholder.typicode.com/todos";

  // Fungsi untuk mengambil data
  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      
      // Cek jika request berhasil (status code 200)
      if (response.statusCode == 200) {
        // Decode body response dari string JSON menjadi List<dynamic>
        List<dynamic> body = jsonDecode(response.body);

        // Map setiap item di list menjadi objek DeliveryTask
        List<DeliveryTask> tasks = body
            .map((dynamic item) => DeliveryTask.fromJson(item))
            .toList();

        return tasks;
      } else {
        // Jika server tidak merespons dengan OK, lempar error
        throw Exception('Gagal memuat data dari API');
      }
    } catch (e) {
      // Menangani error koneksi atau lainnya
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
