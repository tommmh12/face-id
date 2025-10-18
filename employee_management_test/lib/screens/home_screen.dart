import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.business,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hệ Thống Quản Lý Nhân Viên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chấm công bằng Face ID và Tính lương tự động',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main Features
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Employee Management
                  _buildFeatureCard(
                    context,
                    icon: Icons.people,
                    title: 'Quản Lý\nNhân Viên',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/employees'),
                  ),

                  // Department Management
                  _buildFeatureCard(
                    context,
                    icon: Icons.business,
                    title: 'Quản Lý\nPhòng Ban',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/departments'),
                  ),

                  // Face Registration
                  _buildFeatureCard(
                    context,
                    icon: Icons.face,
                    title: 'Đăng Ký\nFace ID',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/face/register'),
                  ),

                  // Check In/Out
                  _buildFeatureCard(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Chấm Công\nFace ID',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/face/checkin'),
                  ),

                  // Payroll Management
                  _buildFeatureCard(
                    context,
                    icon: Icons.attach_money,
                    title: 'Quản Lý\nLương',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),
                ],
              ),
            ),

            // Quick Actions
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/face/checkin'),
                    icon: const Icon(Icons.login),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/face/checkin'),
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}