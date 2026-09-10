/// Estado de "estoy compartiendo mi ubicación" en la rodada en vivo (LV1).
/// No es un flag booleano de carga: es una máquina de estados explícita
/// del flujo de D21.
enum SharingStatus { notSharing, requestingPermission, sharing, stopping }
