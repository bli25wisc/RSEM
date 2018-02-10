SAMTOOLS = samtools-1.7
HTSLIB = htslib-1.7

ifneq ($(cygwin), true)
  SAMTOOLS_MAKEFILE = Makefile
else
  SAMTOOLS_MAKEFILE = Makefile.cygwin
endif

# overridable, defaulting to local copy
BOOST = .

# Compilation variables
CXX = g++
CXXFLAGS = -std=gnu++98 -Wall -I. 
CPPFLAGS = -I$(BOOST) -I$(SAMTOOLS)/$(HTSLIB)

LDFLAGS =
LDLIBS =

# Installation variables
INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -p
INSTALL_DATA = $(INSTALL) -p -m 644
INSTALL_DIR = $(INSTALL) -d
STRIP ?=strip

prefix ?= /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

# Auxiliary variables for compilation
SAMHEADERS = $(SAMTOOLS)/$(HTSLIB)/htslib/bgzf.h $(SAMTOOLS)/$(HTSLIB)/htslib/hts.h $(SAMTOOLS)/$(HTSLIB)/htslib/sam.h $(SAMTOOLS)/$(HTSLIB)/htslib/thread_pool.h
SAMLIBS = $(SAMTOOLS)/$(HTSLIB)/libhts.a
CONFIGURE = ./configure

OBJS1 = Transcript.o Transcripts.o RefSeq.o Refs.o GenomeMap.o buildRef.o SamParser.o BamWriter.o BamAlignment.o gbam2tbam.o
OBJS2 = parseIt.o
# OBJS2 = buildReadIndex.o wiggle.o tbam2gbam.o bam2wig.o bam2readdepth.o getUnique.o samValidator.o scanForPairedEndReads.o SamHeader.o
OBJS3 = EM.o Gibbs.o calcCI.o simulation.o

PROGS1 = rsem-build-reference
PROGS2 = rsem-gbam2tbam
# PROGS2 = rsem-simulate-reads rsem-parse-alignments rsem-run-em rsem-tbam2gbam rsem-bam2wig rsem-bam2readdepth rsem-get-unique rsem-sam-validator rsem-scan-for-paired-end-reads
# PROGS3 = rsem-run-gibbs rsem-calculate-credibility-intervals

PROGRAMS = $(PROGS1) $(PROGS2) $(PROGS3)

# Auxiliary variables for installation
SCRIPTS = rsem-prepare-reference rsem-calculate-expression rsem-refseq-extract-primary-assembly rsem-gff3-to-gtf rsem-plot-model \
	  rsem-plot-transcript-wiggles rsem-gen-transcript-plots rsem-generate-data-matrix \
	  extract-transcript-to-gene-map-from-trinity convert-sam-for-rsem    



.PHONY : all ebseq pRSEM clean

all : $(PROGRAMS) $(SAMTOOLS)/samtools

$(SAMTOOLS)/samtools :
	cd $(SAMTOOLS) && $(CONFIGURE) --without-curses && $(MAKE) -f $(SAMTOOLS_MAKEFILE) samtools

$(SAMLIBS) : $(SAMTOOLS)/samtools


# Compile objects
$(OBJS1) :
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -O3 -c -o $@ $<

$(OBJS2) :
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -O2 -c -o $@ $<

$(OBJS3) :
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -O3 -ffast-math -c -o $@ $<


# Generate executables
$(PROGS1) :
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(PROGS2) :
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS) -lbz2 -lz -lcurl -llzma

$(PROGS3) :
	$(CXX) $(LDFLAGS) -pthread -o $@ $^ $(LDLIBS)


# Dependencies for executables
rsem-build-reference : buildRef.o Transcript.o Transcripts.o RefSeq.o Refs.o GenomeMap.o
rsem-gbam2tbam : gbam2tbam.o $(SAMLIBS) Transcript.o Transcripts.o GenomeMap.o SEQstring.o SamParser.o BamWriter.o BamAlignment.o

rsem-simulate-reads : simulation.o

rsem-parse-alignments : parseIt.o $(SAMLIBS)
rsem-run-em : EM.o SamHeader.o $(SAMLIBS)
rsem-tbam2gbam : tbam2gbam.o SamHeader.o $(SAMLIBS)
rsem-bam2wig : bam2wig.o wiggle.o $(SAMLIBS)
rsem-bam2readdepth : bam2readdepth.o wiggle.o $(SAMLIBS)
rsem-get-unique : getUnique.o $(SAMLIBS)
rsem-sam-validator : samValidator.o $(SAMLIBS)
rsem-scan-for-paired-end-reads : scanForPairedEndReads.o $(SAMLIBS)

rsem-run-gibbs : Gibbs.o
rsem-calculate-credibility-intervals : calcCI.o

# Dependencies for objects
parseIt.o : parseIt.cpp $(SAMHEADERS) sam_utils.h utils.h my_assert.h GroupInfo.h Transcripts.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h HitContainer.h SamParser.h


Transcript.o : Transcript.cpp utils.h my_assert.h Transcript.hpp
Transcripts.o : Transcripts.cpp utils.h my_assert.h Transcript.hpp Transcripts.hpp
RefSeq.o : RefSeq.cpp utils.h my_assert.h RefSeq.hpp
Refs.o : Refs.cpp utils.h my_assert.h RefSeq.hpp Refs.hpp
GenomeMap.o : GenomeMap.cpp my_assert.h Transcript.hpp Transcripts.hpp GenomeMap.hpp 
buildRef.o : buildRef.cpp utils.h my_assert.h GTFItem.h Transcript.hpp Transcripts.hpp RefSeq.hpp Refs.hpp GenomeMap.hpp
SEQstring.o : SEQstring.cpp $(SAMHEADERS) SEQstring.hpp
SamParser.o : SamParser.cpp $(SAMHEADERS) my_assert.h SamParser.hpp
BamWriter.o : BamWriter.cpp $(SAMHEADERS) my_assert.h BamWriter.hpp
BamAlignment.o : BamAlignment.cpp $(SAMHEADERS) my_assert.h CIGARstring.hpp SEQstring.hpp QUALstring.hpp MDstring.hpp SamParser.hpp BamWriter.hpp BamAlignment.hpp
gbam2tbam.o : gbam2tbam.cpp $(SAMHEADERS) utils.h my_assert.h Transcript.hpp Transcripts.hpp GenomeMap.hpp CIGARstring.hpp SEQstring.hpp QUALstring.hpp MDstring.hpp SamParser.hpp BamWriter.hpp BamAlignment.hpp AlignmentGroup.hpp



wiggle.o: wiggle.cpp $(SAMHEADERS) sam_utils.h utils.h my_assert.h wiggle.h
tbam2gbam.o : tbam2gbam.cpp $(SAMHEADERS) utils.h Transcripts.h Transcript.h BamConverter.h sam_utils.h SamHeader.hpp my_assert.h bc_aux.h
bam2wig.o : bam2wig.cpp utils.h my_assert.h wiggle.h
bam2readdepth.o : bam2readdepth.cpp utils.h my_assert.h wiggle.h
getUnique.o : getUnique.cpp $(SAMHEADERS) sam_utils.h utils.h 
samValidator.o : samValidator.cpp $(SAMHEADERS) sam_utils.h utils.h my_assert.h
scanForPairedEndReads.o : scanForPairedEndReads.cpp $(SAMHEADERS) sam_utils.h utils.h my_assert.h 
SamHeader.o : SamHeader.cpp $(SAMHEADERS) SamHeader.hpp 

EM.o : EM.cpp $(SAMHEADERS) utils.h my_assert.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h Refs.h GroupInfo.h HitContainer.h ReadIndex.h ReadReader.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h ModelParams.h RefSeq.h RefSeqPolicy.h PolyARules.h Profile.h NoiseProfile.h Transcript.h Transcripts.h HitWrapper.h BamWriter.h simul.h sam_utils.h SamHeader.hpp sampling.h $(BOOST)/boost/random.hpp WriteResults.h
Gibbs.o : Gibbs.cpp utils.h my_assert.h $(BOOST)/boost/random.hpp sampling.h simul.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h ReadIndex.h ReadReader.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h Profile.h NoiseProfile.h ModelParams.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h RefSeq.h RefSeqPolicy.h PolyARules.h Refs.h GroupInfo.h WriteResults.h 
calcCI.o : calcCI.cpp utils.h my_assert.h $(BOOST)/boost/random.hpp sampling.h simul.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h ReadIndex.h ReadReader.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h Profile.h NoiseProfile.h ModelParams.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h RefSeq.h RefSeqPolicy.h PolyARules.h Refs.h GroupInfo.h WriteResults.h Buffer.h 
simulation.o : simulation.cpp utils.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h Refs.h RefSeq.h GroupInfo.h Transcript.h Transcripts.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h Profile.h NoiseProfile.h simul.h $(BOOST)/boost/random.hpp WriteResults.h

# Dependencies for header files
Transcripts.hpp : Transcript.hpp
RefSeq.hpp : utils.h my_assert.h
Refs.hpp : utils.h my_assert.h RefSeq.hpp
SamParser.hpp : $(SAMHEADERS) utils.h
BamWriter.hpp : $(SAMHEADERS) my_assert.h
BamAlignment.hpp : $(SAMHEADERS) my_assert.h CIGARstring.hpp SEQstring.hpp QUALstring.hpp MDstring.hpp SamParser.hpp BamWriter.hpp
AlignmentGroup.hpp : $(SAMHEADERS) SEQstring.hpp QUALstring.hpp SamParser.hpp BamWriter.hpp BamAlignment.hpp



WriteResults.h : utils.h my_assert.h GroupInfo.h Transcript.h Transcripts.h RefSeq.h Refs.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h
bc_aux.h : $(SAMHEADERS)
BamConverter.h : $(SAMHEADERS) sam_utils.h SamHeader.hpp utils.h my_assert.h bc_aux.h Transcript.h Transcripts.h
Buffer.h : my_assert.h
SamHeader.hpp : $(SAMHEADERS)

# Compile EBSeq
ebseq :
	cd EBSeq && $(MAKE) all

# Compile pRSEM
pRSEM :
	cd pRSEM && $(MAKE) all


# Install RSEM
install : $(PROGRAMS) $(SCRIPTS) $(SAMTOOLS)/samtools rsem_perl_utils.pm
	$(INSTALL_DIR) $(DESTDIR)$(bindir) $(DESTDIR)$(bindir)/$(SAMTOOLS)
	$(foreach prog,$(PROGRAMS),$(INSTALL_PROGRAM) $(prog) $(DESTDIR)$(bindir)/$(prog) ; $(STRIP) $(DESTDIR)$(bindir)/$(prog) ;)
	$(INSTALL_PROGRAM) $(SAMTOOLS)/samtools $(DESTDIR)$(bindir)/$(SAMTOOLS)/samtools
	$(STRIP) $(DESTDIR)$(bindir)/$(SAMTOOLS)/samtools
	$(foreach script,$(SCRIPTS),$(INSTALL_PROGRAM) $(script) $(DESTDIR)$(bindir)/$(script) ;)
	$(INSTALL_DATA) rsem_perl_utils.pm $(DESTDIR)$(bindir)/rsem_perl_utils.pm

# Clean
clean :
	rm -f *.o *~ $(PROGRAMS)
	cd $(SAMTOOLS) && $(MAKE) clean-all
	cd EBSeq && $(MAKE) clean
	cd pRSEM && $(MAKE) clean
