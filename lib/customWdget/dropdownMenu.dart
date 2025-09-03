

import 'package:flutter/material.dart';

import '../constants/Constants.dart';

enum SortOption {
  highToLow,
  lowToHigh,
  rating,
}

class SortDropdownMenu extends StatefulWidget {
  final Function(SortOption?)? onSortChanged;
  final SortOption? initialValue;

  const SortDropdownMenu({
    Key? key,
    this.onSortChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  State<SortDropdownMenu> createState() => _SortDropdownMenuState();
}

class _SortDropdownMenuState extends State<SortDropdownMenu> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  SortOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialValue;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _showDropdown();
    } else {
      _removeOverlay();
    }
  }

  void _showDropdown() {
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible full-screen barrier to detect outside taps
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 8,
            width: 200,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SORT BY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _removeOverlay,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options
                    _buildOption(
                      'High To Low',
                      SortOption.highToLow,
                      isSelected: _selectedOption == SortOption.highToLow,
                    ),
                    _buildOption(
                      'Low To High',
                      SortOption.lowToHigh,
                      isSelected: _selectedOption == SortOption.lowToHigh,
                    ),
                    _buildOption(
                      'Rating',
                      SortOption.rating,
                      isSelected: _selectedOption == SortOption.rating,
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedOption = null;
                                    });
                                    widget.onSortChanged?.call(null);
                                    _removeOverlay();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.onSortChanged?.call(_selectedOption);
                                    _removeOverlay();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5A540),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOption(String label, SortOption value, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
        // Update the overlay to reflect the new selection
        _removeOverlay();
        _showDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFFE5A540) : Colors.grey[700],
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ?Color(0xFFE5A540):Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFE5A540) : Colors.grey[400]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? Icon(Icons.check,color: Colors.white,size: 14,)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        key: _buttonKey,
        onPressed: _toggleDropdown, icon: Icon(
      Icons.filter_alt,
      size: 24,
      color: Constants.ftaColorLight,
    ));

    /*GestureDetector(
      key: _buttonKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5A540),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 20,
            ),
            if (_selectedOption != null) ...[
              const SizedBox(width: 8),
              Text(
                _getSelectedText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );*/
  }

  String _getSelectedText() {
    switch (_selectedOption) {
      case SortOption.highToLow:
        return 'High to Low';
      case SortOption.lowToHigh:
        return 'Low to High';
      case SortOption.rating:
        return 'Rating';
      default:
        return '';
    }
  }
}


class SellerSortDropdownMenu extends StatefulWidget {
  final Function(SortOption?)? onSortChanged;
  final SortOption? initialValue;

  const SellerSortDropdownMenu({
    Key? key,
    this.onSortChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  State<SellerSortDropdownMenu> createState() => _SellerSortDropdownMenuState();
}

class _SellerSortDropdownMenuState extends State<SellerSortDropdownMenu> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  SortOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialValue;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _showDropdown();
    } else {
      _removeOverlay();
    }
  }

  void _showDropdown() {
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible full-screen barrier to detect outside taps
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown
          Positioned(
            left: offset.dx + size.width + 8,
            top: offset.dy + size.height + 8,
            width: 200,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SORT BY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _removeOverlay,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options
                    _buildOption(
                      'High To Low',
                      SortOption.highToLow,
                      isSelected: _selectedOption == SortOption.highToLow,
                    ),
                    _buildOption(
                      'Low To High',
                      SortOption.lowToHigh,
                      isSelected: _selectedOption == SortOption.lowToHigh,
                    ),
                    _buildOption(
                      'Rating',
                      SortOption.rating,
                      isSelected: _selectedOption == SortOption.rating,
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedOption = null;
                                    });
                                    widget.onSortChanged?.call(null);
                                    _removeOverlay();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.onSortChanged?.call(_selectedOption);
                                    _removeOverlay();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5A540),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOption(String label, SortOption value, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
        // Update the overlay to reflect the new selection
        _removeOverlay();
        _showDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFFE5A540) : Colors.grey[700],
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ?Color(0xFFE5A540):Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFE5A540) : Colors.grey[400]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? Icon(Icons.check,color: Colors.white,size: 14,)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        key: _buttonKey,
        onPressed: _toggleDropdown, icon: Icon(
      Icons.filter_alt,
      size: 24,
      color:Colors.white,
    ));

    /*GestureDetector(
      key: _buttonKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5A540),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 20,
            ),
            if (_selectedOption != null) ...[
              const SizedBox(width: 8),
              Text(
                _getSelectedText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );*/
  }

  String _getSelectedText() {
    switch (_selectedOption) {
      case SortOption.highToLow:
        return 'High to Low';
      case SortOption.lowToHigh:
        return 'Low to High';
      case SortOption.rating:
        return 'Rating';
      default:
        return '';
    }
  }
}