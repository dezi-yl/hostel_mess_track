import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/food_attendance_page/bloc/food_attendance_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceDialog extends StatefulWidget {
  final int foodId;
  final String foodName;
  final VoidCallback onClose;

  const AttendanceDialog({
    super.key,
    required this.foodId,
    required this.foodName,
    required this.onClose,
  });

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _regController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _isScannerActive = false;
  String? _feedbackMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
    context.read<FoodAttendanceBloc>().add(ClearSearch());
    _initScanner(); // Initialize once at the beginning
    _isScannerActive = true; // Set scanner to active by default
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isScannerActive = _tabController.index == 1;
      });
    }
    if (_tabController.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scannerController?.start();
      });
    } else {
      _scannerController?.stop();
    }
  }

  void _initScanner() {
    _scannerController = MobileScannerController();
  }

  void _disposeScanner() {
    _scannerController?.dispose();
    _scannerController = null;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _regController.dispose();
    _disposeScanner();
    super.dispose();
  }

  void _handleQRCode(String code) async {
    if (_isProcessing) {
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    _scannerController?.stop(); // Stop scanner immediately

    if (!mounted) {
      return; // Check if the widget is still mounted before using context
    }
    context.read<FoodAttendanceBloc>().add(
      ScanAndMarkAttendance(qrCode: code, foodId: widget.foodId),
    );

    // Resume scanning after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        if (_tabController.index == 1) {
          // Only restart if QR tab is still active
          _scannerController?.start();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return BlocListener<FoodAttendanceBloc, FoodAttendanceState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          setState(() {
            _feedbackMessage = state.successMessage;
            _isError = false;
          });
          context.read<FoodAttendanceBloc>().add(ClearFoodAttendanceMessages());
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _feedbackMessage = null;
              });
            }
          });
        }
        if (state.errorMessage != null) {
          setState(() {
            _feedbackMessage = state.errorMessage;
            _isError = true;
          });
          context.read<FoodAttendanceBloc>().add(ClearFoodAttendanceMessages());
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _feedbackMessage = null;
              });
            }
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 500,
          height: screenHeight * 0.7, // 70% of screen height
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Take Attendance: ${widget.foodName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              if (_feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: _isError ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Search'),
                  Tab(text: 'QR Scan'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSearchTab(), _buildQRTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return BlocBuilder<FoodAttendanceBloc, FoodAttendanceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _regController,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.read<FoodAttendanceBloc>().add(
                      SearchStudent(query: _regController.text),
                    ),
                  ),
                ),
                onSubmitted: (value) => context.read<FoodAttendanceBloc>().add(
                  SearchStudent(query: value),
                ),
              ),
              const SizedBox(height: 20),
              if (state.isSearching)
                const CircularProgressIndicator()
              else if (state.searchedStudents.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: state.searchedStudents.length,
                    itemBuilder: (context, index) {
                      final student = state.searchedStudents[index];
                      return ListTile(
                        title: Text(student.name),
                        subtitle: Text(student.reg),
                        onTap: () {
                          context.read<FoodAttendanceBloc>().add(
                                MarkAttendance(
                                  studentId: student.id,
                                  foodId: widget.foodId,
                                ),
                              );
                          context.read<FoodAttendanceBloc>().add(ClearSearch());
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRTab() {
    if (!_isScannerActive) {
      return const Center(child: Text('Activate QR Scanner'));
    }
    if (_scannerController == null) {
      return const Center(child: Text('Initializing Camera...'));
    }
    return MobileScanner(
      controller: _scannerController!,
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final String? code = barcodes.first.rawValue;
          if (code != null) {
            _handleQRCode(code);
          }
        }
      },
    );
  }
}
