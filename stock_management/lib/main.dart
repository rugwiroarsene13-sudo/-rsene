
import 'package:flutter/material.dart';
import 'stock_database.dart';

void main() {
  runApp(const StockManagementApp());
}

class StockManagementApp extends StatelessWidget {
  const StockManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StockHomePage(),
    );
  }
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isSaving = false;
  int? editingId;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);

    try {
      final records = await StockDatabase.getProducts();

      if (!mounted) return;

      setState(() {
        products = records.map((record) {
          return {
            'id': record.key,
            ...record.value,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Could not load products: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void clearForm() {
    nameController.clear();
    quantityController.clear();
    priceController.clear();
    setState(() => editingId = null);
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim());
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || quantity == null || price == null) {
      showMessage('Enter a product name, whole-number quantity and valid price.');
      return;
    }

    if (quantity < 0 || price < 0) {
      showMessage('Quantity and price cannot be negative.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final product = {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

      if (editingId == null) {
        await StockDatabase.addProduct(product);
      } else {
        await StockDatabase.updateProduct(editingId!, product);
      }

      if (!mounted) return;

      clearForm();
      showMessage('Product saved successfully.');
      await loadProducts();
    } catch (e) {
      showMessage('Could not save product: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void startEditing(Map<String, dynamic> product) {
    setState(() {
      editingId = product['id'] as int;
      nameController.text = product['name'].toString();
      quantityController.text = product['quantity'].toString();
      priceController.text = product['price'].toString();
    });
  }

  Future<void> deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete ${product['name']} from stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StockDatabase.deleteProduct(product['id'] as int);

      if (!mounted) return;

      if (editingId == product['id']) clearForm();

      showMessage('Product deleted successfully.');
      await loadProducts();
    } catch (e) {
      if (mounted) showMessage('Could not delete product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh stock',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        editingId == null ? 'Add New Stock' : 'Update Stock',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: isSaving ? null : saveProduct,
                            icon: Icon(
                              editingId == null ? Icons.add : Icons.save,
                            ),
                            label: Text(
                              editingId == null ? 'Add Product' : 'Update Product',
                            ),
                          ),
                          if (editingId != null)
                            OutlinedButton(
                              onPressed: clearForm,
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Saved Products (${products.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
              if (!isLoading && products.isEmpty)
                const Text('No products saved yet.'),
              if (!isLoading)
                ...products.map(
                  (product) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(product['quantity'].toString()),
                      ),
                      title: Text(product['name'].toString()),
                      subtitle: Text(
                        'Quantity: ${product['quantity']}'
                        ' | Price: ${product['price']}',
                      ),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => startEditing(product),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => deleteProduct(product),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
