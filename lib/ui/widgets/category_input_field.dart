import 'package:flutter/material.dart';
import '../../services/category_service.dart';

/// An autocomplete text field for category input with tag suggestions
class CategoryInputField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final String? hintText;
  final String? labelText;
  final bool enabled;

  const CategoryInputField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.enabled = true,
  });

  @override
  State<CategoryInputField> createState() => _CategoryInputFieldState();
}

class _CategoryInputFieldState extends State<CategoryInputField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadInitialSuggestions() async {
    final suggestions = await CategoryService.instance.getCategorySuggestions('');
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
      });
    }
  }

  void _onTextChanged() async {
    final text = _controller.text;
    widget.onChanged(text);
    
    if (_focusNode.hasFocus) {
      final suggestions = await CategoryService.instance.getCategorySuggestions(text);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
        _updateOverlay();
      }
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = _suggestions.isNotEmpty;
      });
      _updateOverlay();
    } else {
      setState(() {
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  void _onSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    widget.onChanged(suggestion);
    _focusNode.unfocus();
    CategoryService.instance.recordCategoryUsage(suggestion);
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_showSuggestions && _suggestions.isNotEmpty) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final isExact = suggestion.toLowerCase() == _controller.text.toLowerCase();
                
                return InkWell(
                  onTap: () => _onSuggestionTap(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: index < _suggestions.length - 1 
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          )
                        : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExact ? Icons.add : Icons.tag,
                          size: 16,
                          color: isExact 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isExact 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isExact ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isExact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Category',
        hintText: widget.hintText ?? 'e.g., Daily, Health, Work',
        prefixIcon: const Icon(Icons.tag),
        suffixIcon: _controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            )
          : null,
        border: const OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      onFieldSubmitted: (value) {
        if (value.isNotEmpty) {
          CategoryService.instance.recordCategoryUsage(value);
        }
      },
    );
  }
}