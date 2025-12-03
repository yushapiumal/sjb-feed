import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:statelink/screens/old_feed/model/group.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up a new user
  Future<User?> signUp(String email, String password, String role, String name) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user!.sendEmailVerification();
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'verified': false,
        'groups': [],
      });
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('The email address is already in use by another account.');
      } else {
        throw Exception('Error signing up: ${e.message}');
      }
    }
  }

  // Sign in an existing user
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // Update verified status in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).update({
        'verified': cred.user!.emailVerified,
      });
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again or reset your password.');
      } else {
        throw Exception('Error signing in: ${e.message}');
      }
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else {
        throw Exception('Error sending password reset email: ${e.message}');
      }
    }
  }

  // Get user's role
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc['role'];
  }

  // Save FCM token for notifications
  Future<void> saveFCMToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  // Sign out the user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Find user ID by email
  Future<String?> findUserIdByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }

  // Create a new group (only for global admins)
  // Future<String> createGroup(String name, String description, String creatorUid) async {
  //   final userDoc = await _firestore.collection('users').doc(creatorUid).get();
  //   if (userDoc['role'] != 'admin') {
  //     throw Exception('Only admins can create groups');
  //   }

  //   final groupRef = await _firestore.collection('groups').add({
  //     'name': name,
  //     'description': description,
  //     'admins': [creatorUid],
  //     'members': [creatorUid],
  //   });

  //   await _firestore.collection('users').doc(creatorUid).update({
  //     'groups': FieldValue.arrayUnion([
  //       {'groupId': groupRef.id, 'role': 'admin'}
  //     ])
  //   });

  //   return groupRef.id;
  // }

  // Add a user to a group by email (only for group admins)
  // Future<void> addUserToGroup(String groupId, String userEmail, String adminUid) async {
  //   final groupDoc = await _firestore.collection('groups').doc(groupId).get();
  //   if (!groupDoc.exists) {
  //     throw Exception('Group does not exist');
  //   }
  //   final group = Group.fromMap(groupDoc.data()!, groupDoc.id);
  //   if (!group.admins.contains(adminUid)) {
  //     throw Exception('Only group admins can add users');
  //   }

  //   final userId = await findUserIdByEmail(userEmail);
  //   if (userId == null) {
  //     throw Exception('User with email $userEmail does not exist');
  //   }

  //   if (group.members.contains(userId)) {
  //     throw Exception('User is already a member of the group');
  //   }

  //   await _firestore.collection('groups').doc(groupId).update({
  //     'members': FieldValue.arrayUnion([userId]),
  //   });

  //   await _firestore.collection('users').doc(userId).update({
  //     'groups': FieldValue.arrayUnion([
  //       {'groupId': groupId, 'role': 'member'}
  //     ])
  //   });
  // }

  // Join a group
  // Future<void> joinGroup(String groupId, String userId) async {
  //   final groupDoc = await _firestore.collection('groups').doc(groupId).get();
  //   if (!groupDoc.exists) {
  //     throw Exception('Group does not exist');
  //   }
  //   await _firestore.collection('groups').doc(groupId).update({
  //     'members': FieldValue.arrayUnion([userId]),
  //   });

  //   await _firestore.collection('users').doc(userId).update({
  //     'groups': FieldValue.arrayUnion([
  //       {'groupId': groupId, 'role': 'member'}
  //     ])
  //   });
  // }

  // Get groups based on user role
  Future<List<Map<String, dynamic>>> getUserGroups(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userRole = userDoc['role'] ?? 'user';

    if (userRole == 'admin') {
      final groupsSnapshot = await _firestore.collection('groups').get();
      final List<Map<String, dynamic>> allGroups = [];
      for (var doc in groupsSnapshot.docs) {
        final group = Group.fromMap(doc.data(), doc.id);
        final userGroups = List<Map<String, dynamic>>.from(userDoc['groups'] ?? []);
        final groupEntry = userGroups.firstWhere(
          (g) => g['groupId'] == doc.id,
          orElse: () => {'groupId': doc.id, 'role': group.admins.contains(uid) ? 'admin' : 'member'},
        );
        allGroups.add({
          'groupId': doc.id,
          'role': groupEntry['role'],
        });
      }
      return allGroups;
    } else {
      return List<Map<String, dynamic>>.from(userDoc['groups'] ?? []);
    }
  }

  // Check if user is admin of a group
  Future<bool> isGroupAdmin(String groupId, String uid) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      return false;
    }
    final group = Group.fromMap(groupDoc.data()!, groupDoc.id);
    return group.admins.contains(uid);
  }
}