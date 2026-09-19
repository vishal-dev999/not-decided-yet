import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_enums.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../widgets/language_text.dart';

class PaymentTab extends StatefulWidget {
  final AppLanguage language;
  final String paymentPreference;
  final ValueChanged<String> onPaymentPreferenceChanged;
  final ReNovaStorage? storage;

  const PaymentTab({
    super.key,
    required this.language,
    required this.paymentPreference,
    required this.onPaymentPreferenceChanged,
    this.storage,
  });

  @override
  State<PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<PaymentTab> {
  late String selectedMode;
  final TextEditingController upiController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool saveUpiDetails = true;
  String cashStatus = 'received';
  bool qrGenerated = false;

  String _t(String en, String hi, String mr) =>
      LanguageText.t(widget.language, en, hi, mr);

  @override
  void initState() {
    super.initState();
    selectedMode = widget.paymentPreference == 'UPI / Digital Wallet'
        ? 'UPI'
        : 'Cash';
  }

  @override
  void dispose() {
    upiController.dispose();
    accountController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String _upiQrData() {
    final upiId = upiController.text.trim();
    final amount = amountController.text.trim();

    if (upiId.isEmpty) return '';

    final params = <String>[
      'pa=${Uri.encodeComponent(upiId)}',
      'pn=${Uri.encodeComponent('ReNova')}',
      if (amount.isNotEmpty) 'am=${Uri.encodeComponent(amount)}',
      'cu=INR',
    ];

    return 'upi://pay?${params.join('&')}';
  }

  Future<void> _recordPayment() async {
    final mode = selectedMode;
    final details = mode == 'Cash'
        ? (cashStatus == 'received'
            ? _t('Cash received', 'नकद प्राप्त हुआ', 'रोख मिळाली')
            : _t('Cash yet to receive', 'नकद प्राप्त होना बाकी है', 'रोख अजून मिळायची आहे'))
        : (upiController.text.trim().isEmpty
            ? _t('UPI details not entered', 'UPI विवरण दर्ज नहीं किया गया', 'UPI तपशील दिलेला नाही')
            : upiController.text.trim());

    final item = {
      'mode': mode,
      'details': details,
      'amount': amountController.text.trim().isEmpty
          ? '₹1,750'
          : '₹${amountController.text.trim()}',
      'date': DateTime.now().toIso8601String(),
    };

    await widget.storage?.savePayment(item);
    widget.onPaymentPreferenceChanged(
      mode == 'Cash' ? 'Cash' : 'UPI / Digital Wallet',
    );

    if (mode == 'UPI' && saveUpiDetails && upiController.text.trim().isNotEmpty) {
      await widget.storage?.saveUpiId(upiController.text.trim());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(
          'Payment preference saved.',
          'भुगतान पसंद सहेजी गई।',
          'पेमेंट पसंती जतन झाली.',
        )),
      ),
    );
    setState(() {});
  }

  String _formatDate(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return raw ?? '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final history = widget.storage?.paymentHistory ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _t('Payments', 'भुगतान', 'पेमेंट'),
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Choose how you want to receive payment.',
            'भुगतान प्राप्त करने का तरीका चुनें।',
            'पेमेंट कसे घ्यायचे ते निवडा.',
          ),
          style: TextStyle(color: AppThemeColors.muted(context)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _paymentModeCard(
                context,
                'Cash',
                Icons.payments_outlined,
                _t('Cash', 'नकद', 'रोख'),
                accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _paymentModeCard(
                context,
                'UPI',
                Icons.qr_code_2,
                'UPI',
                accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: selectedMode == 'Cash'
              ? _cashDetails(context)
              : _upiDetails(context),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _recordPayment,
            icon: const Icon(Icons.save),
            label: Text(_t('Save Payment Mode', 'भुगतान तरीका सहेजें', 'पेमेंट पद्धत जतन करा')),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _t('Payment History', 'भुगतान इतिहास', 'पेमेंट इतिहास'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Text(
            _t(
              'No payments recorded yet.',
              'अभी कोई भुगतान दर्ज नहीं है।',
              'अजून कोणतेही पेमेंट नोंदलेले नाही.',
            ),
            style: TextStyle(color: AppThemeColors.muted(context)),
          ),
        ...history.map(
          (item) => Card(
            child: ListTile(
              leading: Icon(
                item['mode'] == 'UPI' ? Icons.qr_code_2 : Icons.payments_outlined,
                color: accent,
              ),
              title: Text(
                '${item['mode']} • ${item['amount']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_t('Mode', 'तरीका', 'पद्धत')}: ${item['mode']}\n'
                '${_t('Date', 'तारीख', 'तारीख')}: ${_formatDate(item['date'] as String?)}',
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentModeCard(
    BuildContext context,
    String mode,
    IconData icon,
    String title,
    Color accent,
  ) {
    final selected = selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => selectedMode = mode),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : AppThemeColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: accent),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cashDetails(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Container(
      key: const ValueKey('cash'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments, size: 34),
            title: Text(_t('Cash Payment', 'नकद भुगतान', 'रोख पेमेंट')),
            subtitle: Text(
              _t(
                'Receive the amount in cash and keep the transaction record.',
                'राशि नकद प्राप्त करें और लेनदेन का रिकॉर्ड रखें।',
                'रक्कम रोख घ्या आणि व्यवहाराची नोंद ठेवा.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t('Payment Status', 'भुगतान स्थिति', 'पेमेंट स्थिती'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(_t('Cash received', 'नकद प्राप्त हुआ', 'रोख मिळाली')),
                selected: cashStatus == 'received',
                selectedColor: accent.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => cashStatus = 'received'),
              ),
              ChoiceChip(
                label: Text(_t('Cash yet to receive', 'नकद प्राप्त होना बाकी है', 'रोख अजून मिळायची आहे')),
                selected: cashStatus == 'pending',
                selectedColor: accent.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => cashStatus = 'pending'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upiDetails(BuildContext context) {
    return Container(
      key: const ValueKey('upi'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: upiController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email),
              labelText: _t('UPI ID', 'UPI आईडी', 'UPI आयडी'),
              hintText: 'name@upi',
            ),
            onChanged: (_) => setState(() => qrGenerated = false),
          ),
          if ((widget.storage?.savedUpiId ?? '').isNotEmpty &&
              widget.storage!.savedUpiId != upiController.text.trim()) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.history, size: 16),
                label: Text(
                  '${_t('Recently used', 'हाल ही में उपयोग किया गया', 'अलीकडे वापरलेले')}: ${widget.storage!.savedUpiId}',
                ),
                onPressed: () {
                  setState(() {
                    upiController.text = widget.storage!.savedUpiId!;
                  });
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: accountController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.account_balance),
              labelText: _t('Bank / Wallet Reference (optional)', 'बैंक / वॉलेट संदर्भ (वैकल्पिक)', 'बँक / वॉलेट संदर्भ (पर्यायी)'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.currency_rupee),
              labelText: _t('Amount (₹)', 'राशि (₹)', 'रक्कम (₹)'),
              hintText: 'e.g. 500',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (upiController.text.trim().isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => qrGenerated = true),
                icon: const Icon(Icons.qr_code_2),
                label: Text(_t('Generate UPI', 'UPI जनरेट करें', 'UPI तयार करा')),
              ),
            ),
          if (qrGenerated && _upiQrData().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: _upiQrData(),
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ],
          if (qrGenerated && _upiQrData().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _t('Scan with any UPI app', 'किसी भी UPI ऐप से स्कैन करें', 'कोणत्याही UPI अॅपने स्कॅन करा'),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t('Save UPI details?', 'UPI विवरण सहेजें?', 'UPI तपशील जतन करायचे?'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: Text(_t('Yes', 'हाँ', 'होय')),
                  selected: saveUpiDetails,
                  onSelected: (_) => setState(() => saveUpiDetails = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(_t('No', 'नहीं', 'नाही')),
                  selected: !saveUpiDetails,
                  onSelected: (_) => setState(() => saveUpiDetails = false),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _t(
                'For a real QR/UPI transaction flow, connect a payment gateway in the production backend.',
                'वास्तविक QR/UPI लेनदेन के लिए उत्पादन बैकएंड में पेमेंट गेटवे जोड़ें।',
                'वास्तविक QR/UPI व्यवहारासाठी उत्पादन बॅकएंडमध्ये पेमेंट गेटवे जोडा.',
              ),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
