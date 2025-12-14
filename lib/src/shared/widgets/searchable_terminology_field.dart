import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/disease_calculation/data/terminology_item.dart'; // Pastikan path import ini sesuai

class SearchableTerminologyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<TerminologyItem> dataList;
  final Icon? prefixIcon;
  final int? maxLength;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const SearchableTerminologyField({
    super.key,
    required this.label,
    required this.controller,
    required this.dataList,
    this.prefixIcon,
    this.maxLength,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<TerminologyItem>(
          // 1. Logika Pencarian
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<TerminologyItem>.empty();
            }
            return dataList.where((TerminologyItem option) {
              return option.matches(textEditingValue.text);
            });
          },

          // 2. Tampilan Teks Saat Dipilih
          displayStringForOption: (TerminologyItem option) =>
              '[${option.code}] ${option.label}',

          // 3. Aksi Saat Item Dipilih
          onSelected: (TerminologyItem selection) {
            controller.text = '[${selection.code}] ${selection.label}';
          },

          // 4. Membangun Input Field (TextFormField)
          fieldViewBuilder:
              (
                context,
                fieldTextEditingController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                // Sinkronisasi data awal (saat edit)
                if (controller.text.isNotEmpty &&
                    fieldTextEditingController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Cek mounted tidak wajib di stateless widget tapi good practice jika diubah ke stateful
                    fieldTextEditingController.text = controller.text;
                  });
                }

                // Listener sinkronisasi manual
                fieldTextEditingController.addListener(() {
                  if (controller.text != fieldTextEditingController.text) {
                    controller.text = fieldTextEditingController.text;
                  }
                });

                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,

                  // --- FITUR MULTILINE (WRAPPING) ---
                  maxLines: null, // Tinggi otomatis menyesuaikan isi
                  keyboardType: TextInputType.multiline,

                  // --- PERUBAHAN DI SINI ---
                  textInputAction: TextInputAction
                      .done, // Tombol enter akan menutup keyboard/selesai
                  // --------------------------

                  // --- FITUR MAX LENGTH ---
                  maxLength: maxLength,
                  inputFormatters: maxLength != null
                      ? [LengthLimitingTextInputFormatter(maxLength)]
                      : null,

                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    prefixIcon: prefixIcon ?? const Icon(Icons.search),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  validator: validator,
                );
              },

          // 5. Tampilan List Saran (Dropdown)
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: 250,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TerminologyItem option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${option.code} - ${option.label}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${option.domain} > ${option.category}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
