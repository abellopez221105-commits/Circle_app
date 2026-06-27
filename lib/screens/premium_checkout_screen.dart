import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:provider/provider.dart';
import 'package:circle_app/providers/auth_provider.dart';

class PremiumCheckoutScreen extends StatefulWidget {
  const PremiumCheckoutScreen({super.key});

  @override
  State<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends State<PremiumCheckoutScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    const primaryColor = Color(0xFF3F51B5);

    return Scaffold(
      backgroundColor: Colors.white,
      // 🟢 CONFIGURACIÓN CLAVE: Permite que la pantalla se deslice al abrir el teclado
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Finalizar Compra', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // 🟢 CAMBIO ESTRUCTURAL: Usamos un SingleChildScrollView como contenedor principal del cuerpo
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── 1. PAYWALL BANNER SUPERIOR ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: primaryColor.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('GO PREMIUM ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                        Text('Circles ilimitados, insignias doradas, y eventos destacados.', style: TextStyle(fontSize: 13, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── 2. WIDGET DE TARJETA VISUAL ───
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused, 
              obscureCardNumber: true,
              obscureCardCvv: true,
              isHolderNameVisible: true,
              cardBgColor: primaryColor,
              onCreditCardWidgetChange: (CreditCardBrand brand) {},
            ),

            // ─── 3. FORMULARIO DE ENTRADA DETALLADO ───
            CreditCardForm(
              formKey: formKey,
              obscureCvv: true,
              obscureNumber: true,
              cardNumber: cardNumber,
              cvvCode: cvvCode,
              isHolderNameVisible: true,
              cardHolderName: cardHolderName,
              expiryDate: expiryDate,
              
              inputConfiguration: InputConfiguration(
                cardHolderDecoration: _inputDecoration('Titular de la tarjeta', Icons.person_outline, primaryColor),
                cardNumberDecoration: _inputDecoration('Número de Tarjeta', Icons.credit_card_outlined, primaryColor),
                expiryDateDecoration: _inputDecoration('Fecha de Exp. (MM/AA)', Icons.calendar_today_outlined, primaryColor),
                cvvCodeDecoration: _inputDecoration('CVV', Icons.lock_outline, primaryColor),
              ),
              
              onCreditCardModelChange: (CreditCardModel data) {
                setState(() {
                  cardNumber = data.cardNumber;
                  expiryDate = data.expiryDate;
                  cardHolderName = data.cardHolderName;
                  cvvCode = data.cvvCode;
                  isCvvFocused = data.isCvvFocused;
                });
              },
            ),
            
            const SizedBox(height: 20),
            const Text(
              '* Tip: Usa 4242... para éxito (Sandbox sim)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),

            // ─── 4. BOTÓN DE ACCIÓN FINAL ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: authProvider.isProcessingPayment
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                      ),
                      onPressed: () => _handlePayment(authProvider),
                      child: const Text(
                        'PAGAR \$9.99 / MES (Simulado)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color focusColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      floatingLabelStyle: TextStyle(color: focusColor),
      prefixIcon: Icon(icon, size: 22),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusColor;
        return Colors.grey;
      }),
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Future<void> _handlePayment(AuthProvider authProvider) async {
    if (formKey.currentState!.validate()) {
      final result = await authProvider.processSandboxPayment(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvvCode,
        cardHolder: cardHolderName,
      );

      if (!mounted) return;

      if (result == 'success') {
        await authProvider.loadUserProfile();

        if (!mounted) return;

        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡🎉 Bienvenido a Circle Premium! Tu suscripción está activa.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}