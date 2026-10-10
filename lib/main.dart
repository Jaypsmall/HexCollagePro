import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

// --- Premium Gold Colors ---
const Color goldDark = Color(0xFF8C6221);
const Color goldMedium = Color(0xFFC29B47);
const Color goldLight = Color(0xFFFFF3A8);

const LinearGradient premiumGoldGradient = LinearGradient(
  colors: [goldDark, goldLight, goldMedium, goldDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// --- Model ---
class CollageConfig {
  final int tileSize;
  final int mediumImages;
  final int bigImages;
  final int sizeMin;
  final int sizeMax;
  final double blurBase;
  final double brightnessBase;
  final double contrastFinal;
  final double glowChance;
  final int numOverlay;
  final bool rotateRandom;
  final bool modeFull;

  const CollageConfig({
    this.tileSize = 120,
    this.mediumImages = 20,
    this.bigImages = 5,
    this.sizeMin = 150,
    this.sizeMax = 400,
    this.blurBase = 8.0,
    this.brightnessBase = 0.4,
    this.contrastFinal = 1.2,
    this.glowChance = 0.3,
    this.numOverlay = 30,
    this.rotateRandom = true,
    this.modeFull = false,
  });

  CollageConfig copyWith({
    int? tileSize,
    int? mediumImages,
    int? bigImages,
    int? sizeMin,
    int? sizeMax,
    double? blurBase,
    double? brightnessBase,
    double? contrastFinal,
    double? glowChance,
    int? numOverlay,
    bool? rotateRandom,
    bool? modeFull,
  }) {
    return CollageConfig(
      tileSize: tileSize ?? this.tileSize,
      mediumImages: mediumImages ?? this.mediumImages,
      bigImages: bigImages ?? this.bigImages,
      sizeMin: sizeMin ?? this.sizeMin,
      sizeMax: sizeMax ?? this.sizeMax,
      blurBase: blurBase ?? this.blurBase,
      brightnessBase: brightnessBase ?? this.brightnessBase,
      contrastFinal: contrastFinal ?? this.contrastFinal,
      glowChance: glowChance ?? this.glowChance,
      numOverlay: numOverlay ?? this.numOverlay,
      rotateRandom: rotateRandom ?? this.rotateRandom,
      modeFull: modeFull ?? this.modeFull,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HexCollageApp());
}

class HexCollageApp extends StatelessWidget {
  const HexCollageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hex Collage Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: goldMedium,
        colorScheme: const ColorScheme.dark(
          primary: goldMedium,
          surface: Color(0xFF0F0F0F),
        ),
      ),
      home: const CollageApp(),
    );
  }
}

class CollageApp extends StatefulWidget {
  const CollageApp({super.key});

  @override
  State<CollageApp> createState() => _CollageAppState();
}

class _CollageAppState extends State<CollageApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _repaintKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  List<String> _imagePaths = [];
  CollageConfig _config = const CollageConfig();
  bool _isExporting = false;

  Future<void> _pickImages() async {
    if (_isExporting) return;
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imagePaths = pickedFiles.map((f) => f.path).toList();
        });
      }
    } catch (e) {
      _showSnackbar('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _exportCollage() async {
    if (_imagePaths.isEmpty) {
      _showSnackbar('Añade fotos primero');
      return;
    }
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('No se pudo encontrar la imagen');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('No se pudo procesar la imagen');
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      await Gal.putImageBytes(
        bytes,
        name: 'HexCollage_${DateTime.now().millisecondsSinceEpoch}',
      );

      _showSnackbar('¡Obra Maestra Guardada! ✨');
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _randomizeConfig() {
    final rand = math.Random();
    setState(() {
      _config = _config.copyWith(
        mediumImages: rand.nextInt(60) + 10,
        rotateRandom: rand.nextBool(),
        modeFull: rand.nextBool(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF050505),
      drawer: Drawer(
        width: 320,
        backgroundColor: const Color(0xFF0F0F0F),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Divider(
                color: goldDark.withValues(alpha: 0.3),
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDrawerSectionTitle("MODOS DE ARTE"),
                    _buildDrawerItem("CLEAN", Icons.auto_awesome, () {
                      setState(() {
                        _config = _config.copyWith(
                          mediumImages: 10,
                          bigImages: 2,
                          rotateRandom: false,
                          modeFull: false,
                        );
                      });
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem("RAP STYLE", Icons.music_note, () {
                      setState(() {
                        _config = _config.copyWith(
                          mediumImages: 25,
                          bigImages: 5,
                          rotateRandom: true,
                          modeFull: false,
                        );
                      });
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem("TOTAL CHAOS", Icons.whatshot, () {
                      setState(() {
                        _config = _config.copyWith(
                          mediumImages: 45,
                          bigImages: 12,
                          rotateRandom: true,
                          modeFull: true,
                        );
                      });
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem("VIDEOCLIP", Icons.movie, () {
                      setState(() {
                        _config = _config.copyWith(
                          mediumImages: 35,
                          bigImages: 8,
                          rotateRandom: true,
                          modeFull: false,
                        );
                      });
                      Navigator.pop(context);
                    }),
                    const SizedBox(height: 20),
                    _buildDrawerSectionTitle("MOTOR AJUSTES"),
                    _buildSettingSlider(
                      label: "Capas",
                      value: _config.mediumImages.toDouble(),
                      min: 5,
                      max: 80,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(mediumImages: val.toInt());
                        });
                      },
                    ),
                    _buildSettingSlider(
                      label: "Héroes",
                      value: _config.bigImages.toDouble(),
                      min: 1,
                      max: 20,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(bigImages: val.toInt());
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerSwitch(
                      label: "Rotación Dinámica",
                      value: _config.rotateRandom,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(rotateRandom: val);
                        });
                      },
                    ),
                    _buildDrawerSwitch(
                      label: "Fondo Caótico",
                      value: _config.modeFull,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(modeFull: val);
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Credits Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          premiumGoldGradient.createShader(bounds),
                      child: const Text(
                        "HEX COLLAGE PRO v1.0",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Created by JAYLIZ with ❤️",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => premiumGoldGradient.createShader(bounds),
          child: const Text(
            'HEX COLLAGE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: 6,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: goldMedium, size: 30),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: goldMedium),
            onPressed: _randomizeConfig,
          ),
        ],
      ),
      body: SizedBox.expand(
        child: _imagePaths.isEmpty
            ? _buildEmptyState()
            : RepaintBoundary(
                key: _repaintKey,
                child: CollageCanvas(
                  imagePaths: _imagePaths,
                  config: _config,
                ),
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: goldDark.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: "📂 FOTOS",
                  onClick: _pickImages,
                  enabled: !_isExporting,
                  isAction: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PremiumButton(
                  text: _isExporting ? "" : "🎬 EXPORTAR",
                  onClick: _exportCollage,
                  enabled: !_isExporting && _imagePaths.isNotEmpty,
                  isAction: true, // GOLD BUTTON
                  child: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: premiumGoldGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: const Text(
                'HX',
                style: TextStyle(
                  color: goldLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => premiumGoldGradient.createShader(bounds),
            child: const Text(
              'HEX COLLAGE PRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'CREATIVE ART STUDIO',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: goldMedium,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: goldMedium, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSwitch(
      {required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: goldLight,
            activeTrackColor: goldDark,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: goldLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: goldMedium,
              inactiveTrackColor: Color(0xFF333333),
              thumbColor: goldMedium,
              overlayColor: Color(0x33C29B47),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 120,
                  color: goldDark.withValues(alpha: 0.5),
                ),
                const Icon(
                  Icons.photo_library,
                  size: 80,
                  color: goldLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) =>
                premiumGoldGradient.createShader(bounds),
            child: const Text(
              'ESTUDIO HEX',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'IMPORTA FOTOS PARA EMPEZAR',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// --- GOLD BUTTON COMPONENT ---
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onClick;
  final bool enabled;
  final bool isAction;
  final Widget? child;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onClick,
    this.enabled = true,
    this.isAction = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAction
        ? premiumGoldGradient
        : const LinearGradient(
            colors: [Color(0xFF222222), Color(0xFF111111)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final textColor = isAction ? Colors.black : Colors.white;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: bgColor,
        border: Border.all(
          width: 1.5,
          color: isAction ? goldLight : const Color(0xFF444444),
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: isAction
                      ? goldMedium.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onClick : null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      color: enabled ? textColor : Colors.grey,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (child != null) ...[child!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CANVAS COMPONENT ---
class CollageCanvas extends StatelessWidget {
  final List<String> imagePaths;
  final CollageConfig config;

  const CollageCanvas({
    super.key,
    required this.imagePaths,
    required this.config,
  });

  double _nextGaussian(math.Random random) {
    double u1 = random.nextDouble();
    double u2 = random.nextDouble();
    while (u1 <= 1e-15) {
      u1 = random.nextDouble();
    }
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final math.Random random = math.Random(
          imagePaths.length +
              config.mediumImages +
              config.bigImages +
              (config.modeFull ? 100 : 0),
        );

        List<Widget> collageItems = [];

        if (!config.modeFull) {
          final int totalImages = config.mediumImages + config.bigImages;
          final int count = math.min(totalImages, 60);

          for (int index = 0; index < count; index++) {
            final String path = imagePaths[index % imagePaths.length];
            final bool isHero = index >= config.mediumImages;

            final double spread = isHero ? 6.0 : 4.5;
            final double xOffset = _nextGaussian(random) * (width / spread);
            final double yOffset = _nextGaussian(random) * (height / spread);

            final double rotation = config.rotateRandom
                ? (random.nextInt(46) - 23).toDouble() * (math.pi / 180.0)
                : 0.0;

            final double size = isHero
                ? (random.nextInt(
                            math.max(1, config.sizeMax - (config.sizeMax ~/ 2))) +
                        (config.sizeMax ~/ 2))
                    .toDouble()
                : (random.nextInt(math.max(1, config.sizeMax - config.sizeMin)) +
                        config.sizeMin)
                    .toDouble();

            final bool hasGlow =
                isHero && random.nextDouble() < config.glowChance;

            collageItems.add(
              Positioned(
                left: (width / 2) + xOffset - (size / 2),
                top: (height / 2) + yOffset - (size / 2),
                child: Transform.rotate(
                  angle: rotation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasGlow)
                        Container(
                          width: size + 20,
                          height: size + 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: goldMedium.withValues(alpha: 0.3),
                            boxShadow: [
                              BoxShadow(
                                color: goldMedium.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: isHero
                                  ? goldDark.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.8),
                              blurRadius: isHero ? 40 : 15,
                              spreadRadius: isHero ? 2 : 0,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          final int count = math.min(imagePaths.length, 60);
          for (int index = 0; index < count; index++) {
            final String path = imagePaths[index];
            final double rotation =
                (random.nextInt(70) - 35).toDouble() * (math.pi / 180.0);
            final double size = (random.nextInt(250) + 120).toDouble();
            final double xPos =
                (random.nextInt(math.max(1, width.toInt() + 300)) - 150)
                    .toDouble();
            final double yPos =
                (random.nextInt(math.max(1, height.toInt() + 300)) - 150)
                    .toDouble();

            collageItems.add(
              Positioned(
                left: xPos,
                top: yPos,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: goldDark.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Container(
          color: const Color(0xFF020202),
          child: Stack(
            clipBehavior: Clip.none,
            children: collageItems,
          ),
        );
      },
    );
  }
}
