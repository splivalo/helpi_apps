import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/shared/models/selected_address_info.dart';

/// Google Places autocomplete field for address input.
/// Vraća [SelectedAddressInfo] kroz [onAddressSelected] callback.
class McAddressField extends StatefulWidget {
  const McAddressField({
    super.key,
    required this.onAddressSelected,
    this.controller,
    this.label,
    this.validator,
  });

  final void Function(SelectedAddressInfo) onAddressSelected;
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;

  @override
  State<McAddressField> createState() => _McAddressFieldState();
}

class _McAddressFieldState extends State<McAddressField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    final label = widget.label ?? AppStrings.address;

    return GooglePlaceAutoCompleteTextField(
      textEditingController: _controller,
      googleAPIKey: apiKey,
      debounceTime: 300,
      countries: const ['hr'],
      isLatLngRequired: true,
      focusNode: _focusNode,
      isCrossBtnShown: false,
      textInputAction: TextInputAction.none,
      boxDecoration: const BoxDecoration(),
      inputDecoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      itemClick: (Prediction prediction) {
        _controller.text = prediction.description ?? '';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      getPlaceDetailWithLatLng: (Prediction prediction) {
        final placeId = prediction.placeId ?? '';
        final lat = double.tryParse(prediction.lat ?? '') ?? 0.0;
        final lng = double.tryParse(prediction.lng ?? '') ?? 0.0;

        widget.onAddressSelected(
          SelectedAddressInfo(
            placeId: placeId,
            fullAddress: prediction.description ?? '',
            lat: lat,
            lng: lng,
          ),
        );
      },
    );
  }
}
