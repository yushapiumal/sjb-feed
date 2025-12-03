// // lib/screens/group_selection_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:statelink/models/group.dart';
// import 'package:statelink/provider/auth_provider.dart';
// import 'package:statelink/screens/wall_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class GroupSelectionScreen extends StatefulWidget {
//   const GroupSelectionScreen({super.key});

//   @override
//   State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
// }

// class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
//   // Define the gradient for reuse
//   static const LinearGradient _appGradient = LinearGradient(
//     colors: [Colors.green, Colors.yellow],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final userGroups = authProvider.groups;
//     final isGlobalAdmin = authProvider.isGlobalAdmin;

//     return Scaffold(
//       backgroundColor: Colors.transparent, // Ensure Scaffold doesn't override gradient
//       appBar: AppBar(
//         title: const Text(
//           'Your Groups',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: _appGradient,
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: _appGradient,
//         ),
//         child: userGroups.isEmpty
//             ? Center(
//                 child: Text(
//                   isGlobalAdmin
//                       ? 'No groups available. Create a group!'
//                       : 'No groups yet. Ask an admin to add you!',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             : ListView.builder(
//                 padding: const EdgeInsets.all(16.0),
//                 itemCount: userGroups.length,
//                 itemBuilder: (context, index) {
//                   final groupData = userGroups[index];
//                   final groupId = groupData['groupId'];
//                   return FutureBuilder<DocumentSnapshot>(
//                     future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return Card(
//                           color: Colors.white.withOpacity(0.9),
//                           child: const ListTile(
//                             title: Text('Loading...'),
//                           ),
//                         );
//                       }
//                       if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
//                         return Card(
//                           color: Colors.white.withOpacity(0.9),
//                           child: ListTile(
//                             title: const Text('Error loading group'),
//                             subtitle: Text('Group ID: $groupId'),
//                           ),
//                         );
//                       }
//                       final group = Group.fromMap(snapshot.data!.data() as Map<String, dynamic>, groupId);
//                       return FutureBuilder<bool>(
//                         future: authProvider.isGroupAdmin(groupId),
//                         builder: (context, adminSnapshot) {
//                           final isGroupAdmin = adminSnapshot.data ?? false;
//                           return Card(
//                             elevation: 4,
//                             color: Colors.white.withOpacity(0.9),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             margin: const EdgeInsets.symmetric(vertical: 8),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.all(16),
//                               leading: CircleAvatar(
//                                 backgroundColor: Colors.green,
//                                 child: Text(
//                                   group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
//                                   style: const TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               title: Text(
//                                 group.name.isNotEmpty ? group.name : 'Unnamed Group',
//                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                               ),
//                               subtitle: Text(
//                                 group.description.isNotEmpty ? group.description : 'No description',
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Chip(
//                                     label: Text(
//                                       groupData['role'] == 'admin' ? 'Admin' : 'Member',
//                                       style: TextStyle(
//                                         color: groupData['role'] == 'admin' ? Colors.green : Colors.grey,
//                                       ),
//                                     ),
//                                     backgroundColor: Colors.white,
//                                   ),
//                                   if (isGroupAdmin)
//                                     IconButton(
//                                       icon: const Icon(Icons.person_add, color: Colors.green),
//                                       onPressed: () => _showAddUserDialog(context, groupId),
//                                     ),
//                                 ],
//                               ),
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => WallScreen(groupId: groupId),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2);
//                         },
//                       );
//                     },
//                   );
//                 },
//               ),
//       ),
//       floatingActionButton: isGlobalAdmin
//           ? FloatingActionButton(
//               onPressed: () => _showCreateGroupBottomSheet(context),
//               backgroundColor: Colors.green,
//               child: const Icon(Icons.add, color: Colors.white),
//               tooltip: 'Create New Group',
//             )
//           : null,
//       floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
//     );
//   }

//   void _showCreateGroupBottomSheet(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final _groupNameController = TextEditingController();
//     final _groupDescriptionController = TextEditingController();
//     bool _isLoading = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           decoration: const BoxDecoration(
//             gradient: _appGradient,
//           ),
//           child: StatefulBuilder(
//             builder: (context, setState) {
//               return Padding(
//                 padding: EdgeInsets.only(
//                   bottom: MediaQuery.of(context).viewInsets.bottom,
//                   left: 16,
//                   right: 16,
//                   top: 16,
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Create New Group',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ).animate().fadeIn(duration: 400.ms),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _groupNameController,
//                       decoration: InputDecoration(
//                         labelText: 'Group Name',
//                         labelStyle: const TextStyle(color: Colors.white),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         filled: true,
//                         fillColor: Colors.white.withOpacity(0.9),
//                         errorText: _groupNameController.text.isEmpty && _isLoading
//                             ? 'Group name is required'
//                             : null,
//                       ),
//                       style: const TextStyle(color: Colors.black),
//                     ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _groupDescriptionController,
//                       decoration: InputDecoration(
//                         labelText: 'Description (optional)',
//                         labelStyle: const TextStyle(color: Colors.white),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         filled: true,
//                         fillColor: Colors.white.withOpacity(0.9),
//                       ),
//                       style: const TextStyle(color: Colors.black),
//                       maxLines: 2,
//                     ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
//                     const SizedBox(height: 16),
//                     _isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : ElevatedButton(
//                             onPressed: () async {
//                               if (_groupNameController.text.isNotEmpty) {
//                                 setState(() => _isLoading = true);
//                                 try {
//                                   final groupId = await authProvider.createGroup(
//                                     _groupNameController.text,
//                                     _groupDescriptionController.text,
//                                   );
//                                   Navigator.pop(context);
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => WallScreen(groupId: groupId),
//                                     ),
//                                   );
//                                 } catch (e) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(content: Text('Error creating group: $e')),
//                                   );
//                                 } finally {
//                                   setState(() => _isLoading = false);
//                                 }
//                               } else {
//                                 setState(() => _isLoading = true);
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               minimumSize: const Size(double.infinity, 50),
//                               backgroundColor: Colors.green,
//                               foregroundColor: Colors.white,
//                             ),
//                             child: const Text(
//                               'Create Group',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ).animate().fadeIn(delay: 400.ms).scale(),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   void _showAddUserDialog(BuildContext context, String groupId) {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final _userEmailController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return Container(
//           decoration: const BoxDecoration(
//             gradient: _appGradient,
//           ),
//           child: AlertDialog(
//             backgroundColor: Colors.white.withOpacity(0.9),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             title: const Text(
//               'Add User to Group',
//               style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//             ),
//             content: TextField(
//               controller: _userEmailController,
//               decoration: InputDecoration(
//                 labelText: 'User Email',
//                 labelStyle: const TextStyle(color: Colors.black),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 filled: true,
//                 fillColor: Colors.white.withOpacity(0.9),
//               ),
//               style: const TextStyle(color: Colors.black),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel', style: TextStyle(color: Colors.black)),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (_userEmailController.text.isNotEmpty) {
//                     try {
//                       await authProvider.addUserToGroup(groupId, _userEmailController.text);
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('User added successfully')),
//                       );
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Error adding user: $e')),
//                       );
//                     }
//                   }
//                 },
//                 child: const Text('Add', style: TextStyle(color: Colors.green)),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }