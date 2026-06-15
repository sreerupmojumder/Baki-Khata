import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tali_khata/admin/admin_profile_screen.dart';

// কাস্টমার মডেল ক্লাস
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final double totalDue;
  final DateTime lastUpdated;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.lastUpdated,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? 'Unknown',
      phone: map['phone'] ?? '',
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['last_updated'] != null
          ? (map['last_updated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class DueManagementScreen extends StatefulWidget {
  const DueManagementScreen({super.key});

  @override
  State<DueManagementScreen> createState() => _DueManagementScreenState();
}

class _DueManagementScreenState extends State<DueManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dueController = TextEditingController();
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initFirestoreOffline();
  }

  void _initFirestoreOffline() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ১. নতুন কাস্টমার যুক্ত করার ফাংশন
  Future<void> _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();
      String phone = _phoneController.text.trim();
      double due = double.tryParse(_dueController.text.trim()) ?? 0.0;

      if (phone.isNotEmpty) {
        if (mounted) Navigator.pop(context);
        try {
          final querySnapshot = await _firestore
              .collection('Customers')
              .where('phone', isEqualTo: phone)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('এই মোবাইল নম্বরটি ($phone) ইতিমধ্যে এন্ট্রি করা আছে!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          debugPrint("Error checking duplicate: $e");
        }
      } else {
        if (mounted) Navigator.pop(context);
      }

      DocumentReference docRef = await _firestore.collection('Customers').add({
        'name': name,
        'phone': phone,
        'total_due': due,
        'last_updated': FieldValue.serverTimestamp(),
      });

      if (due != 0) {
        await _firestore.collection('Transactions').add({
          'customer_id': docRef.id,
          'type': due > 0 ? 'বাকি যোগ' : 'অগ্রিম জমা',
          'amount': due.abs(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _nameController.clear();
      _phoneController.clear();
      _dueController.clear();
    }
  }

  // ২. কাস্টমারের নাম ও মোবাইল নম্বর এডিট করা
  Future<void> _updateCustomerInfo(String customerId) async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('Customers').doc(customerId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'last_updated': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _phoneController.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  // ৩. কাস্টমার ডিলিট করা
  Future<void> _deleteCustomer(String customerId) async {
    await _firestore.collection('Customers').doc(customerId).delete();
    var history = await _firestore.collection('Transactions').where('customer_id', isEqualTo: customerId).get();
    for (var doc in history.docs) {
      await doc.reference.delete();
    }
  }

  // ৪. কাস্টমার ফর্ম ডায়ালগ
  void _showCustomerFormDialog({CustomerModel? customer}) {
    final isEditMode = customer != null;
    if (isEditMode) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
    } else {
      _nameController.clear();
      _phoneController.clear();
      _dueController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditMode ? 'কাস্টমারের তথ্য সংশোধন' : 'নতুন কাস্টমার ও বাকি এন্ট্রি'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'কাস্টমারের নাম', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'নাম লিখুন' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'মোবাইল নম্বর', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                if (!isEditMode) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _dueController,
                    decoration: const InputDecoration(labelText: 'বাকি টাকার পরিমাণ (ঐচ্ছিক)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _phoneController.clear();
              Navigator.pop(context);
            },
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEditMode) {
                _updateCustomerInfo(customer.id);
              } else {
                _addCustomer();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(isEditMode ? 'আপডেট করুন' : 'সংরক্ষণ করুন', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ৫. বাকি টাকা যোগ বা জমা নেওয়ার ডায়ালগ
  void _showUpdateDueDialog(CustomerModel customer, bool isAddingDue) {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isAddingDue ? 'নতুন বাকি যোগ করুন' : 'বাকি টাকা জমা নিন'),
            const SizedBox(height: 4),
            Text(
              '${customer.name} (${customer.totalDue >= 0 ? "বর্তমান বাকি" : "অগ্রিম জমা"}: ৳${customer.totalDue.abs().toStringAsFixed(1)})',
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'টাকার পরিমাণ', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount > 0) {
                double newDue = isAddingDue ? customer.totalDue + amount : customer.totalDue - amount;

                await _firestore.collection('Customers').doc(customer.id).update({
                  'total_due': newDue,
                  'last_updated': FieldValue.serverTimestamp(),
                });

                await _firestore.collection('Transactions').add({
                  'customer_id': customer.id,
                  'type': isAddingDue ? 'বাকি যোগ' : 'টাকা জমা',
                  'amount': amount,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isAddingDue ? Colors.orange : Colors.green),
            child: Text(isAddingDue ? 'বাকি যোগ করুন' : 'জমা রাখুন', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কাস্টমার ডিলিট করুন'),
        content: Text('আপনি কি নিশ্চিত যে "${customer.name}" এর হিসাব ও সমস্ত ইতিহাস চিরতরে মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              await _deleteCustomer(customer.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ডিলিট করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'নাম বা মোবাইল নম্বর দিয়ে খুঁজুন...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() { _searchQuery = value.trim().toLowerCase(); });
                },
              )
            : const Text('বাকি খাতা', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          _isSearching
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setState(() { _isSearching = false; _searchController.clear(); _searchQuery = ""; }); })
              : IconButton(icon: const Icon(Icons.search), onPressed: () { setState(() { _isSearching = true; }); }),
        
          IconButton(
    icon: const Icon(Icons.account_circle, size: 28),
    tooltip: 'অ্যাডমিন প্রোফাইল',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
      );
    },
  ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Customers').orderBy('last_updated', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('এখনো কোনো বাকির হিসাব এন্ট্রি করা হয়নি।'));

          final docs = snapshot.data!.docs;
          List<CustomerModel> customers = docs.map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          if (_searchQuery.isNotEmpty) {
            customers = customers.where((c) => c.name.toLowerCase().contains(_searchQuery) || c.phone.contains(_searchQuery)).toList();
          }

          if (customers.isEmpty) return const Center(child: Text('কোনো কাস্টমার খুঁজে পাওয়া যায়নি।'));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final bool isAdvance = customer.totalDue < 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
                  leading: CircleAvatar(
                    backgroundColor: isAdvance ? Colors.green.shade50 : (customer.totalDue > 0 ? Colors.red.shade50 : Colors.grey.shade100),
                    child: Icon(Icons.person, color: isAdvance ? Colors.green : (customer.totalDue > 0 ? Colors.red : Colors.grey)),
                  ),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer.phone.isNotEmpty) Text('ফোন: ${customer.phone}'),
                      Text('শেষ লেনদেন: ${DateFormat('dd MMM, yyyy').format(customer.lastUpdated)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isAdvance ? 'অগ্রিম জমা' : 'বাকি টাকা',
                            style: TextStyle(fontSize: 10, color: isAdvance ? Colors.green.shade700 : Colors.grey),
                          ),
                          Text(
                            '৳${customer.totalDue.abs().toStringAsFixed(1)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isAdvance ? Colors.green.shade700 : (customer.totalDue > 0 ? Colors.red.shade700 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.teal),
                        tooltip: 'লেনদেন বিবরণী',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CustomerHistoryScreen(customer: customer)),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Colors.orange),
                              title: const Text('নতুন বাকি যোগ করুন'),
                              onTap: () { Navigator.pop(context); _showUpdateDueDialog(customer, true); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.remove_circle_outline, color: Colors.green),
                              title: const Text('টাকা জমা নিন (বাকি কমান / অগ্রিম)'),
                              onTap: () { Navigator.pop(context); _showUpdateDueDialog(customer, false); },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                              title: const Text('কাস্টমারের তথ্য সংশোধন করুন'),
                              onTap: () { Navigator.pop(context); _showCustomerFormDialog(customer: customer); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('কাস্টমার ডিলিট করুন'),
                              onTap: () { Navigator.pop(context); _showDeleteConfirmationDialog(customer); },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerFormDialog(),
        backgroundColor: Colors.teal[800],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

// --- ফিক্সড কাস্টমার লেনদেনের বিবরণী (Fixed History Screen) ---
class CustomerHistoryScreen extends StatelessWidget {
  final CustomerModel customer;
  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${customer.name} - এর খতিয়ান', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(customer.phone.isNotEmpty ? 'মোবাইল: ${customer.phone}' : 'কোনো নম্বর নেই', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ফিক্স: ইনডেক্সিং এর এরর এড়াতে শুধু .where ব্যবহার করে Dart লেভেলে সর্টিং করা হয়েছে
        stream: firestore
            .collection('Transactions')
            .where('customer_id', isEqualTo: customer.id)
            .snapshots(),
        builder: (context, snapshot) {
          // ১. ডেটা লোড হওয়ার সময়ে ইন্ডিকেটর দেখাবে
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // ২. ট্রানজেকশন কালেকশনে কোনো ডকুমেন্ট না থাকলে বা খালি থাকলে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildLayout(
              customer: customer,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'এই কাস্টমারের কোনো লেনদেনের ইতিহাস পাওয়া যায়নি।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          // ৩. ডাটা পাওয়া গেলে সেটিকে ডেট অনুযায়ী সর্ট করা
          final docs = snapshot.data!.docs;
          
          // ফায়ারবেসের কুয়েরির পরিবর্তে মেমোরিতে সর্ট করা হলো যাতে ইনডেক্স ক্রাশ না করে
          List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            
            final Timestamp aTime = aData['timestamp'] ?? Timestamp.now();
            final Timestamp bTime = bData['timestamp'] ?? Timestamp.now();
            
            return bTime.compareTo(aTime); // ল্যাটেস্ট ট্রানজেকশন সবার উপরে থাকবে
          });

          return _buildLayout(
            customer: customer,
            child: ListView.builder(
              itemCount: sortedDocs.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final data = sortedDocs[index].data() as Map<String, dynamic>;
                final String type = data['type'] ?? 'লেনদেন';
                final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                
                DateTime dateTime = DateTime.now();
                if (data['timestamp'] != null) {
                  dateTime = (data['timestamp'] as Timestamp).toDate();
                }

                final bool isCredit = type == 'টাকা জমা' || type == 'অগ্রিম জমা';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(dateTime),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Text(
                      '৳${amount.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // স্ক্রিনের কমন লেআউট ঠিক রাখার জন্য হেল্পার উইজেট
  Widget _buildLayout({required CustomerModel customer, required Widget child}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('বর্তমান স্থিতি:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                customer.totalDue >= 0 
                    ? 'বাকি: ৳${customer.totalDue.toStringAsFixed(1)}'
                    : 'অগ্রিম জমা: ৳${customer.totalDue.abs().toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: customer.totalDue >= 0 ? Colors.red.shade700 : Colors.green.shade700
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}