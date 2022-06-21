//
// Quantify mirna with bowtie and mirtop
//

include { INDEX_GENOME      } from '../../modules/local/bowtie_genome'
include { BAM_SORT_SAMTOOLS } from '../nf-core/bam_sort_samtools'
include { BOWTIE_MAP_SEQ as BOWTIE_MAP_GENOME } from '../../modules/local/bowtie_map_mirna'

workflow GENOME_QUANT {
    take:
    fasta
    bt_index
    reads      // channel: [ val(meta), [ reads ] ]

    main:
    ch_versions = Channel.empty()

    if (!bt_index){
        INDEX_GENOME ( fasta )
        bowtie_indices      = INDEX_GENOME.out.bowtie_indices
        fasta_formatted = INDEX_GENOME.out.fasta
        ch_versions     = ch_versions.mix(INDEX_GENOME.out.versions)
    } else {
        bowtie_indices      = Channel.fromPath("${bt_index}**ebwt", checkIfExists: true).ifEmpty { exit 1, "Bowtie1 index directory not found: ${bt_index}" }
        fasta_formatted = fasta
    }

    if (bowtie_indices){
        BOWTIE_MAP_GENOME ( reads, bowtie_indices.collect() )
        ch_versions = ch_versions.mix(BOWTIE_MAP_GENOME.out.versions)

        BAM_SORT_SAMTOOLS ( BOWTIE_MAP_GENOME.out.bam, Channel.empty()  )
        ch_versions = ch_versions.mix(BAM_SORT_SAMTOOLS.out.versions)
    }

    emit:
    fasta    = fasta_formatted
    indices  = bowtie_indices
    stats    = BAM_SORT_SAMTOOLS.out.stats

    versions = ch_versions
}
