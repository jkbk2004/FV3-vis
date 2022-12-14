!> @file
!
!> SUBPROGRAM:    FIXED       POSTS FIXED FIELDS
!!   PRGRMMR: TREADON         ORG: W/NP2      DATE: 93-08-30
!!     
!! ABSTRACT:  THIS ROUTINE POSTS FIXED (IE, TIME INDEPENDENT)
!!  ETA MODEL FIELDS.
!!     
!! PROGRAM HISTORY LOG:
!!   93-08-30  RUSS TREADON
!!   96-04-05  MIKE BALDWIN - CHANGED ALBEDO CALC
!!   98-06-16  T BLACK      - CONVERSION FROM 1-D TO 2-D
!!   98-07-17  MIKE BALDWIN - REMOVED LABL84
!!   00-01-05  JIM TUCCILLO - MPI VERSION
!!   02-06-19  MIKE BALDWIN - WRF VERSION
!!   11-02-06  JUN WANG     - grib2 option
!!   20-03-25  JESSE MENG   - remove grib1
!!   21-04-01  JESSE MENG   - computation on defined points only
!!   21-10-15  JESSE MENG   - 2D DECOMPOSITION
!!     
!! USAGE:    CALL FIXED
!!   INPUT ARGUMENT LIST:
!!
!!   OUTPUT ARGUMENT LIST: 
!!     NONE 
!!     
!!   OUTPUT FILES:
!!     NONE
!!     
!!   SUBPROGRAMS CALLED:
!!     UTILITIES:
!!       NONE
!!     LIBRARY:
!!       COMMON   - LOOPS
!!                  MASKS
!!                  LLGRDS
!!                  RQSTFLD
!!                  PHYS
!!     
!!   ATTRIBUTES:
!!     LANGUAGE: FORTRAN
!!     MACHINE : CRAY C-90
!!
      SUBROUTINE FIXED
!

!
      use vrbls3d, only: pint
      use vrbls2d, only: albedo, avgalbedo, albase, mxsnal, sst, ths, epsr, ti&
          , fdnsst
      use masks, only: gdlat, gdlon, sm, sice, lmh, lmv
      use params_mod, only: small, p1000, capa
      use lookup_mod, only: ITB,JTB,ITBQ,JTBQ
      use ctlblk_mod, only: jsta, jend, modelname, grib, cfld, fld_info, datapd, spval, tsrfc,&
              ifhr, ifmin, lm, im, jm, ista, iend
      use rqstfld_mod, only: iget, lvls, iavblfld, id
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      implicit none
!     
      integer,PARAMETER :: SNOALB=0.55
!     INCLUDE COMMON BLOCKS.
!
!     DECLARE VARIABLES
      REAL,dimension(im,jm) :: GRID1
!     REAL,dimension(im,jm) :: GRID1, GRID2
      integer I,J,ITSRFC,IFINCR
!     
!********************************************************************
!
!     START FIXED HERE.
!
!     LATITUDE (OUTPUT GRID).
      IF (IGET(048)>0) THEN
!$omp parallel do private(i,j)
         DO J = JSTA,JEND
            DO I = ISTA,IEND
               GRID1(I,J) = GDLAT(I,J)
            END DO
         END DO
         if(grib=='grib2') then
          cfld=cfld+1
          fld_info(cfld)%ifld=IAVBLFLD(IGET(048))
          datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!     
!     LONGITUDE (OUTPUT GRID). CONVERT TO EAST
      IF (IGET(049)>0) THEN
         DO J = JSTA,JEND
            DO I = ISTA,IEND
             IF (GDLON(I,J) < 0.)THEN            
               GRID1(I,J) = 360. + GDLON(I,J)
             ELSE
               GRID1(I,J) = GDLON(I,J)
             END IF
             IF (GRID1(I,J)>360.)print*,'LARGE GDLON ',      &
             i,j,GDLON(I,J)
            END DO
         END DO
         if(grib=='grib2') then
           cfld=cfld+1
           fld_info(cfld)%ifld=IAVBLFLD(IGET(049))
           datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!     
!     LAND/SEA MASK.
      IF (IGET(050)>0) THEN
!$omp parallel do private(i,j)
         DO J = JSTA,JEND
           DO I = ISTA,IEND
             GRID1(I,J) = SPVAL
              IF(SM(I,J)   /= SPVAL) GRID1(I,J) = 1. - SM(I,J)
              If(MODELNAME == 'GFS' .or. MODELNAME == 'FV3R')then
               IF(SICE(I,J) /= SPVAL .AND. SICE(I,J) > 0.0)GRID1(I,J)=0.
              else 
               IF(SICE(I,J) /= SPVAL .AND. SICE(I,J) > 0.1)GRID1(I,J)=0.
              end if
!           if(j==jm/2)print*,'i,mask= ',i,grid1(i,j)
           ENDDO
         ENDDO
         if(grib=='grib2') then
           cfld=cfld+1
           fld_info(cfld)%ifld=IAVBLFLD(IGET(050))
           datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!     
!     SEA ICE MASK.
      IF (IGET(051)>0) THEN
!$omp parallel do private(i,j)
         DO J = JSTA,JEND
           DO I = ISTA,IEND
             GRID1(I,J) = SICE(I,J)
           ENDDO
         ENDDO
          if(grib=='grib2') then
          cfld=cfld+1
          fld_info(cfld)%ifld=IAVBLFLD(IGET(051))
          datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!     
!     MASS POINT ETA SURFACE MASK.
      IF (IGET(052)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             GRID1(I,J) = LMH(I,J)
           ENDDO
         ENDDO
         if(grib=='grib2') then
          cfld=cfld+1
          fld_info(cfld)%ifld=IAVBLFLD(IGET(052))
          datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!     
!     VELOCITY POINT ETA SURFACE MASK.
      IF (IGET(053)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             GRID1(I,J) = LMV(I,J)
           ENDDO
         ENDDO
          if(grib=='grib2') then
          cfld=cfld+1
          fld_info(cfld)%ifld=IAVBLFLD(IGET(053))
          datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!
!     SURFACE ALBEDO.
!       NO LONGER A FIXED FIELD, THIS VARIES WITH SNOW COVER
!MEB since this is not a fixed field, move this to SURFCE
!
      IF (IGET(150)>0) THEN
!$omp parallel do private(i,j)
       DO J=JSTA,JEND
         DO I=ISTA,IEND
!           SNOK = AMAX1(SNO(I,J),0.0)
!           SNOFAC = AMIN1(SNOK*50.0,1.0)
!           EGRID1(I,J)=ALB(I,J)+(1.-VEGFRC(I,J))*SNOFAC
!     1                *(SNOALB-ALB(I,J))
          IF(ABS(ALBEDO(I,J)-SPVAL)>SMALL) THEN
           GRID1(I,J)=ALBEDO(I,J)
          ELSE
           GRID1(I,J) = SPVAL
          ENDIF
         ENDDO
       ENDDO
!       CALL E2OUT(150,000,GRID1,GRID2,GRID1,GRID2,IM,JM)
       CALL SCLFLD(GRID1(ista:iend,jsta:jend),100.,IM,JM)
       if(grib=='grib2') then
        cfld=cfld+1
        fld_info(cfld)%ifld=IAVBLFLD(IGET(150))
        datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
       endif
      ENDIF
!      
!     TIME AVERAGED SURFACE ALBEDO.
      IF (IGET(266)>0) THEN
            ID(1:25) = 0
            ITSRFC     = NINT(TSRFC)
            IF(ITSRFC /= 0) then
             IFINCR     = MOD(IFHR,ITSRFC)
             IF(IFMIN >= 1)IFINCR= MOD(IFHR*60+IFMIN,ITSRFC*60)
            ELSE
              IFINCR     = 0
            endif
            ID(19)     = IFHR
            IF(IFMIN >= 1)ID(19)=IFHR*60+IFMIN
            ID(20)     = 3
            IF (IFINCR==0) THEN
               ID(18) = IFHR-ITSRFC
            ELSE
               ID(18) = IFHR-IFINCR
               IF(IFMIN >= 1)ID(18)=IFHR*60+IFMIN-IFINCR
            ENDIF
            IF (ID(18)<0) ID(18) = 0
!$omp parallel do private(i,j)
            DO J=JSTA,JEND
              DO I=ISTA,IEND
                IF(ABS(AVGALBEDO(I,J)-SPVAL)>SMALL) THEN
                  GRID1(I,J) = AVGALBEDO(I,J)*100.
                ELSE
                  GRID1(I,J) = SPVAL
                ENDIF
              ENDDO
            ENDDO
       
            if(grib=='grib2') then
             cfld=cfld+1
             fld_info(cfld)%ifld=IAVBLFLD(IGET(266))
             if(ITSRFC>0) then
               fld_info(cfld)%ntrange=1
             else
               fld_info(cfld)%ntrange=0
             endif
             fld_info(cfld)%tinvstat=IFHR-ID(18)
             datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
            endif
      ENDIF
!
      IF (IGET(226)>0) THEN
!$omp parallel do private(i,j)
        DO J=JSTA,JEND
          DO I=ISTA,IEND
            IF(ABS(ALBASE(I,J)-SPVAL)>SMALL) THEN                  
                GRID1(I,J) = ALBASE(I,J)*100.
            ELSE
                GRID1(I,J) = SPVAL
            ENDIF
         ENDDO
        ENDDO
       if(grib=='grib2') then
        cfld=cfld+1
        fld_info(cfld)%ifld=IAVBLFLD(IGET(226))
        datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
       endif
      ENDIF
!  Max snow albedo
      IF (IGET(227)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             IF (ABS(MXSNAL(I,J)-SPVAL)>SMALL) THEN
! sea point, albedo=0.06 same as snow free albedo
             IF( (abs(SM(I,J)-1.) < 1.0E-5) ) THEN
               MXSNAL(I,J)=0.06
! sea-ice point, albedo=0.60, same as snow free albedo
             ELSEIF( (abs(SM(I,J)-0.)   < 1.0E-5) .AND.             &
     &               (abs(SICE(I,J)-1.) < 1.0E-5) ) THEN
               MXSNAL(I,J)=0.60
             ENDIF
             ELSE
               MXSNAL(I,J)=SPVAL
             ENDIF
           ENDDO
         ENDDO
       
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             IF(ABS(MXSNAL(I,J)-SPVAL)>SMALL) THEN                      
               GRID1(I,J) = MXSNAL(I,J)*100.
             ELSE
               GRID1(I,J) = SPVAL
             ENDIF
           ENDDO
         ENDDO
       if(grib=='grib2') then
        cfld=cfld+1
        fld_info(cfld)%ifld=IAVBLFLD(IGET(227))
        datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
       endif
      ENDIF
!
!     SEA SURFACE TEMPERAURE.
      IF (IGET(151)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             GRID1(I,J) = SPVAL
             IF (MODELNAME == 'NMM') THEN
               IF( (abs(SM(I,J)-1.) < 1.0E-5) ) THEN
                 GRID1(I,J) = SST(I,J)
               ELSE
                 IF(THS(I,J)<SPVAL.and.PINT(I,J,LM+1)<SPVAL)&
                  GRID1(I,J) = THS(I,J)*(PINT(I,J,LM+1)/P1000)**CAPA
               END IF  
             ELSE
               GRID1(I,J) = SST(I,J)
             ENDIF
           ENDDO
         ENDDO
         if(grib=='grib2') then
          cfld=cfld+1
          fld_info(cfld)%ifld=IAVBLFLD(IGET(151))
          datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF

!
!     SEA ICE SKIN TEMPERAURE.
      IF (IGET(968)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             GRID1(I,J) = TI(I,J)
           ENDDO
         ENDDO
         if(grib=='grib2') then
           cfld=cfld+1
           fld_info(cfld)%ifld=IAVBLFLD(IGET(968))
           datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF
!
!     FOUNDATION TEMPERAURE.
      IF (IGET(549)>0) THEN
!$omp parallel do private(i,j)
         DO J=JSTA,JEND
           DO I=ISTA,IEND
             GRID1(I,J) = FDNSST(I,J)
           ENDDO
         ENDDO
         if(grib=='grib2') then
           cfld=cfld+1
           fld_info(cfld)%ifld=IAVBLFLD(IGET(549))
           datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
         endif
      ENDIF

!     EMISSIVIT.
       IF (IGET(248)>0) THEN
!$omp parallel do private(i,j)
          DO J=JSTA,JEND
            DO I=ISTA,IEND
              GRID1(I,J) = EPSR(I,J)
            ENDDO
          ENDDO
        if(grib=='grib2') then
           cfld=cfld+1
           fld_info(cfld)%ifld=IAVBLFLD(IGET(248))
           datapd(1:iend-ista+1,1:jend-jsta+1,cfld)=GRID1(ista:iend,jsta:jend)
          endif
       ENDIF

!
!     END OF ROUTINE.
!     
      RETURN
      END

