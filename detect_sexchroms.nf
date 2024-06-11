#!/usr/bin/env nextflow

// No default values
params.reference = ""
params.fastq_reads1 = ""
params.fastq_reads2 = ""
params.output_prefix = ""

process indexReference {

    conda 'bwa-mem2'

    script:
    """
    bwa-mem2 index $params.reference
    """
}

process mapReads {

    conda 'bwa-mem2'

    output:
    stdout

    script:
    """
    bwa-mem2 mem $params.reference $params.fastq_reads1 $params.fastq_reads2
    """
}

process depthPerChromosome {

    conda 'samtools'

    input:
    stdin

    script:
    """
    samtools depth $input | cut -f1,4 > ${params.output_prefix}.depths
    """
}

process normaliseDepths {

    conda 'python pandas'

    input:
    "${params.output_prefix}.depths"

    script:
    """
    #!/usr/bin/env python
    import pandas as pd

    depths = pd.read_csv("${params.output_prefix}.depths")
    mean_depth = depths.iloc[:, 1].mean()
    depths["normalised_depth"] = depths.iloc[:,1] / mean_depth
    depths.to_csv(${params.output_prefix}.normalised)
    """
}

workflow {
    indexReference | mapReads | depthPerChromosome //| normaliseDepths
}