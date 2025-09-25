import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// -----------------------------------------------------------------------------
// Página do Mapa da Sala
// -----------------------------------------------------------------------------
/// Mostra a localização de uma sala específica num mapa e a posição do utilizador.
// -----------------------------------------------------------------------------
class MapaSalaPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String nomeSala;

  const MapaSalaPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.nomeSala,
  });

  @override
  State<MapaSalaPage> createState() => _MapaSalaPageState();
}

class _MapaSalaPageState extends State<MapaSalaPage> {
  // Controlador para o Google Maps.
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  // Posição do utilizador.
  Position? _posicaoAtualUtilizador;

  @override
  void initState() {
    super.initState();
    _verificarPermissoesEObterLocalizacao();
  }

  /// Verifica as permissões de localização e obtém a posição do utilizador.
  Future<void> _verificarPermissoesEObterLocalizacao() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativo.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Se não estiver, não podemos continuar.
      return Future.error('Os serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Se o utilizador negar a permissão, não podemos obter a localização.
        return Future.error('As permissões de localização foram negadas.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Se as permissões forem negadas permanentemente, não podemos pedir novamente.
      return Future.error(
          'As permissões de localização foram negadas permanentemente.');
    }

    // Se tudo estiver certo, obtém a localização e atualiza o estado.
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _posicaoAtualUtilizador = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Posição inicial da câmara, centrada na sala.
    final CameraPosition posicaoInicial = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 16.0,
    );

    // Cria o conjunto de marcadores para o mapa.
    final Set<Marker> marcadores = {
      // Marcador para a sala.
      Marker(
        markerId: MarkerId(widget.nomeSala),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: widget.nomeSala,
          snippet: 'Localização da sala de reunião',
        ),
      ),
      // Se tivermos a localização do utilizador, adiciona um marcador para ele.
      if (_posicaoAtualUtilizador != null)
        Marker(
          markerId: const MarkerId('posicaoUtilizador'),
          position: LatLng(_posicaoAtualUtilizador!.latitude,
              _posicaoAtualUtilizador!.longitude),
          infoWindow: const InfoWindow(title: 'A sua Posição'),
          // Ícone azul para diferenciar.
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Localização: ${widget.nomeSala}'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: posicaoInicial,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: marcadores,
      ),
    );
  }
}
