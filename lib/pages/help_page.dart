import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I add new voice notes?",
      "answer":
          "Tap the floating '+' button on the home screen to pick an audio file from your device, or share an audio file directly from other apps to Audiood.",
    },
    {
      "question": "How do I assign audio to a contact?",
      "answer":
          "When you upload or share audio, the Target Picker dialog will appear. Select an existing contact, or tap 'Create New Person & Add' to create a new profile.",
    },
    {
      "question": "Where is my data stored?",
      "answer":
          "All your voice notes and profiles are securely stored locally on your device. We value your privacy, so there are no cloud uploads or tracking.",
    },
    {
      "question": "How do I delete voice notes?",
      "answer":
          "Long press on any voice note tile on the home screen to prompt the permanent deletion dialog.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs =
        _faqs.where((faq) {
          final q = faq["question"]!.toLowerCase();
          final a = faq["answer"]!.toLowerCase();
          final query = _searchQuery.toLowerCase();
          return q.contains(query) || a.contains(query);
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // 1. Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search help topics...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. FAQs Section Header
          Row(
            children: [
              Icon(Icons.question_answer_outlined, color: Colors.yellow[300]),
              const SizedBox(width: 8),
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. FAQ Items
          if (filteredFaqs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  "No matching topics found.",
                  style: TextStyle(color: Colors.yellow[100], fontSize: 14),
                ),
              ),
            )
          else
            ...filteredFaqs.map(
              (faq) => _buildFaqTile(faq["question"]!, faq["answer"]!),
            ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),

          // 4. Developer Credits Widget
          _buildDeveloperCredits(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.yellow[300],
          collapsedIconColor: Colors.white70,
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Text(
                answer,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCredits() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code_rounded, color: Colors.yellow[300]),
              const SizedBox(width: 8),
              const Text(
                "App Developers",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDeveloperNameRow("Sreenandan S"),
          const SizedBox(height: 8),
          _buildDeveloperNameRow("Sonal Santhosh"),
          const SizedBox(height: 8),
          _buildDeveloperNameRow("Abhai Sankar P R"),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDeveloperNameRow(String name) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.yellow[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
