
import 'package:flutter/material.dart';

void main() {
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Management',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const StockHomePage(),
    );
  }
}

class Product {
  String name;
  double price;
  int quantity;

  Product({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  final List<Product> products = [
    Product(name: 'Indomie', price: 500, quantity: 20),
    Product(name: 'Sugar', price: 1500, quantity: 10),
    Product(name: 'Rice', price: 2000, quantity: 15),
  ];

  double get totalValue => products.fold(
        0,
        (sum, product) => sum + product.price * product.quantity,
      );

  int get totalItems =>
      products.fold(0, (sum, product) => sum + product.quantity);

  void showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter product name'
                          : null,
                ),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (RWF)',
                  ),
                  validator: (value) {
                    final price = double.tryParse(value ?? '');
                    if (price == null || !price.isFinite || price <= 0) {
                      return 'Enter a valid positive price';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity < 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              setState(() {
                products.add(
                  Product(
                    name: nameController.text.trim(),
                    price: double.parse(priceController.text),
                    quantity: int.parse(quantityController.text),
                  ),
                );
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      priceController.dispose();
      quantityController.dispose();
    });
  }

  void changeQuantity(Product product, int change) {
    setState(() {
      if (product.quantity + change >= 0) {
        product.quantity += change;
      }
    });
  }

  void deleteProduct(Product product) {
    setState(() {
      products.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2),
                          const Text('Total Units'),
                          Text(
                            '$totalItems',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Icon(Icons.payments),
                          const Text('Stock Value'),
                          Text(
                            '${totalValue.toStringAsFixed(0)} RWF',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Product List',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No products yet. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.inventory),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.price.toStringAsFixed(0)} RWF each'
                            '\nQuantity: ${product.quantity}',
                          ),
                          isThreeLine: true,
                          trailing: SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Decrease quantity',
                                  onPressed: product.quantity > 0
                                      ? () => changeQuantity(product, -1)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Increase quantity',
                                  onPressed: () =>
                                      changeQuantity(product, 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Delete product',
                                  onPressed: () => deleteProduct(product),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
