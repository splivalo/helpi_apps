/// Predefined Zagreb University faculties.
class Faculty {
  const Faculty({required this.acronym, required this.fullName});

  final String acronym;
  final String fullName;

  static const List<Faculty> all = [
    Faculty(acronym: 'AF', fullName: 'Arhitektonski fakultet'),
    Faculty(acronym: 'AGR', fullName: 'Agronomski fakultet'),
    Faculty(acronym: 'ERF', fullName: 'Edukacijsko-rehabilitacijski fakultet'),
    Faculty(acronym: 'EFZG', fullName: 'Ekonomski fakultet'),
    Faculty(acronym: 'FER', fullName: 'Fakultet elektrotehnike i računarstva'),
    Faculty(
      acronym: 'FFRZ',
      fullName: 'Fakultet filozofije i religijskih znanosti',
    ),
    Faculty(acronym: 'FHS', fullName: 'Fakultet hrvatskih studija'),
    Faculty(
      acronym: 'FKIT',
      fullName: 'Fakultet kemijskog inženjerstva i tehnologije',
    ),
    Faculty(acronym: 'FOI', fullName: 'Fakultet organizacije i informatike'),
    Faculty(acronym: 'FPZG', fullName: 'Fakultet političkih znanosti'),
    Faculty(acronym: 'FPZ', fullName: 'Fakultet prometnih znanosti'),
    Faculty(acronym: 'FSB', fullName: 'Fakultet strojarstva i brodogradnje'),
    Faculty(
      acronym: 'FŠDT',
      fullName: 'Fakultet šumarstva i drvne tehnologije',
    ),
    Faculty(acronym: 'FBF', fullName: 'Farmaceutsko-biokemijski fakultet'),
    Faculty(acronym: 'FFZG', fullName: 'Filozofski fakultet'),
    Faculty(acronym: 'GEOF', fullName: 'Geodetski fakultet'),
    Faculty(acronym: 'GEOTEH', fullName: 'Geotehnički fakultet'),
    Faculty(acronym: 'GF', fullName: 'Građevinski fakultet'),
    Faculty(acronym: 'GRF', fullName: 'Grafički fakultet'),
    Faculty(acronym: 'KBF', fullName: 'Katolički bogoslovni fakultet'),
    Faculty(acronym: 'KIF', fullName: 'Kineziološki fakultet'),
    Faculty(acronym: 'MEF', fullName: 'Medicinski fakultet'),
    Faculty(acronym: 'MET', fullName: 'Metalurški fakultet'),
    Faculty(acronym: 'PRAVO', fullName: 'Pravni fakultet'),
    Faculty(acronym: 'PBF', fullName: 'Prehrambeno-biotehnološki fakultet'),
    Faculty(acronym: 'PMF', fullName: 'Prirodoslovno-matematički fakultet'),
    Faculty(acronym: 'RGN', fullName: 'Rudarsko-geološko-naftni fakultet'),
    Faculty(acronym: 'SFZG', fullName: 'Stomatološki fakultet'),
    Faculty(acronym: 'TTF', fullName: 'Tekstilno–tehnološki fakultet'),
    Faculty(acronym: 'UFZG', fullName: 'Učiteljski fakultet'),
    Faculty(acronym: 'VEF', fullName: 'Veterinarski fakultet'),
  ];

  /// Lookup by acronym. Returns null if not found.
  static Faculty? byAcronym(String acronym) {
    final upper = acronym.toUpperCase();
    for (final f in all) {
      if (f.acronym.toUpperCase() == upper) return f;
    }
    return null;
  }
}
