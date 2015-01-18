   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of residual_block in forward (tangent) mode (with options i4 dr8 r8):
   !   variations   of useful results: *p *dw *w *(*viscsubface.tau)
   !   with respect to varying inputs: *rev *p *sfacei *sfacej *gamma
   !                *sfacek *dw *w *rlv *x *vol *si *sj *sk *radi
   !                *radj *radk gammainf timeref rhoinf tref winf
   !                pinfcorr rgas
   !   Plus diff mem management of: rev:in wx:in wy:in wz:in p:in
   !                sfacei:in sfacej:in gamma:in sfacek:in dw:in w:in
   !                rlv:in x:in qx:in qy:in qz:in ux:in vol:in uy:in
   !                uz:in si:in sj:in sk:in vx:in vy:in vz:in fw:in
   !                viscsubface:in *viscsubface.tau:in radi:in radj:in
   !                radk:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          residual.f90                                    *
   !      * Author:        Edwin van der Weide, Steve Repsher (blanking)   *
   !      * Starting date: 03-15-2003                                      *
   !      * Last modified: 10-29-2007                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE RESIDUAL_BLOCK_D()
   !
   !      ******************************************************************
   !      *                                                                *
   !      * residual computes the residual of the mean flow equations on   *
   !      * the current MG level.                                          *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BLOCKPOINTERS
   USE CGNSGRID
   USE FLOWVARREFSTATE
   USE INPUTITERATION
   USE INPUTDISCRETIZATION
   USE INPUTTIMESPECTRAL
   USE ITERATION
   USE INPUTADJOINT
   USE DIFFSIZES
   !  Hint: ISIZE1OFDrfviscsubface should be the size of dimension 1 of array *viscsubface
   IMPLICIT NONE
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: discr
   INTEGER(kind=inttype) :: i, j, k, l
   REAL(kind=realtype), PARAMETER :: k1=1.05_realType
   ! Random given number
   REAL(kind=realtype), PARAMETER :: k2=0.6_realType
   ! Mach number preconditioner activation
   REAL(kind=realtype), PARAMETER :: m0=0.2_realType
   REAL(kind=realtype), PARAMETER :: alpha=0_realType
   REAL(kind=realtype), PARAMETER :: delta=0_realType
   !real(kind=realType), parameter :: hinf = 2_realType ! Test phase 
   ! Test phase
   REAL(kind=realtype), PARAMETER :: cpres=4.18_realType
   REAL(kind=realtype), PARAMETER :: temp=297.15_realType
   !
   !     Local variables
   !
   REAL(kind=realtype) :: k3, h, velxrho, velyrho, velzrho, sos, hinf, &
   & resm, a11, a12, a13, a14, a15, a21, a22, a23, a24, a25, a31, a32, a33&
   & , a34, a35
   REAL(kind=realtype) :: k3d, velxrhod, velyrhod, velzrhod, sosd, resmd&
   & , a11d, a15d, a21d, a22d, a25d, a31d, a33d, a35d
   REAL(kind=realtype) :: a41, a42, a43, a44, a45, a51, a52, a53, a54, &
   & a55, b11, b12, b13, b14, b15, b21, b22, b23, b24, b25, b31, b32, b33, &
   & b34, b35
   REAL(kind=realtype) :: a41d, a44d, a45d, a51d, a52d, a53d, a54d, a55d&
   & , b11d, b12d, b13d, b14d, b15d, b21d, b22d, b23d, b24d, b25d, b31d, &
   & b32d, b33d, b34d, b35d
   REAL(kind=realtype) :: b41, b42, b43, b44, b45, b51, b52, b53, b54, &
   & b55
   REAL(kind=realtype) :: b41d, b42d, b43d, b44d, b45d, b51d, b52d, b53d&
   & , b54d, b55d
   REAL(kind=realtype) :: rhohdash, betamr2
   REAL(kind=realtype) :: betamr2d
   REAL(kind=realtype) :: g, q
   REAL(kind=realtype) :: qd
   REAL(kind=realtype) :: b1, b2, b3, b4, b5
   REAL(kind=realtype) :: dwo(nwf)
   REAL(kind=realtype) :: dwod(nwf)
   LOGICAL :: finegrid
   INTRINSIC SQRT
   INTRINSIC MAX
   INTRINSIC MIN
   INTRINSIC REAL
   REAL(kind=realtype) :: arg1
   REAL(kind=realtype) :: arg1d
   REAL(kind=realtype) :: result1
   REAL(kind=realtype) :: result1d
   REAL(kind=realtype) :: x1
   REAL(kind=realtype) :: x1d
   INTEGER :: ii1
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Add the source terms from the level 0 cooling model.
   ! Set the value of rFil, which controls the fraction of the old
   ! dissipation residual to be used. This is only for the runge-kutta
   ! schemes; for other smoothers rFil is simply set to 1.0.
   ! Note the index rkStage+1 for cdisRK. The reason is that the
   ! residual computation is performed before rkStage is incremented.
   IF (smoother .EQ. rungekutta) THEN
   rfil = cdisrk(rkstage+1)
   ELSE
   rfil = one
   END IF
   ! Initialize the local arrays to monitor the massflows to zero.
   ! Set the value of the discretization, depending on the grid level,
   ! and the logical fineGrid, which indicates whether or not this
   ! is the finest grid level of the current mg cycle.
   discr = spacediscrcoarse
   IF (currentlevel .EQ. 1) discr = spacediscr
   finegrid = .false.
   IF (currentlevel .EQ. groundlevel) finegrid = .true.
   CALL INVISCIDCENTRALFLUX_D()
   ! Compute the artificial dissipation fluxes.
   ! This depends on the parameter discr.
   SELECT CASE  (discr) 
   CASE (dissscalar) 
   ! Standard scalar dissipation scheme.
   IF (finegrid) THEN
   IF (.NOT.lumpeddiss) THEN
   CALL INVISCIDDISSFLUXSCALAR_D()
   ELSE
   CALL INVISCIDDISSFLUXSCALARAPPROX_D()
   END IF
   ELSE
   fwd = 0.0_8
   END IF
   CASE (dissmatrix) 
   !===========================================================
   ! Matrix dissipation scheme.
   IF (finegrid) THEN
   IF (.NOT.lumpeddiss) THEN
   CALL INVISCIDDISSFLUXMATRIX_D()
   ELSE
   CALL INVISCIDDISSFLUXMATRIXAPPROX_D()
   END IF
   ELSE
   fwd = 0.0_8
   END IF
   CASE (disscusp) 
   fwd = 0.0_8
   CASE (upwind) 
   !===========================================================
   ! Cusp dissipation scheme.
   !===========================================================
   ! Dissipation via an upwind scheme.
   CALL INVISCIDUPWINDFLUX_D(finegrid)
   CASE DEFAULT
   fwd = 0.0_8
   END SELECT
   ! Compute the viscous flux in case of a viscous computation.
   IF (viscous) THEN
   ! not lumpedDiss means it isn't the PC...call the vicousFlux
   IF (.NOT.lumpeddiss) THEN
   CALL VISCOUSFLUX_D()
   ELSE IF (viscpc) THEN
   ! This is a PC calc...only include viscous fluxes if viscPC
   ! is used
   CALL VISCOUSFLUX_D()
   ELSE
   CALL VISCOUSFLUXAPPROX_D()
   DO ii1=1,ISIZE1OFDrfviscsubface
   viscsubfaced(ii1)%tau = 0.0_8
   END DO
   END IF
   ELSE
   DO ii1=1,ISIZE1OFDrfviscsubface
   viscsubfaced(ii1)%tau = 0.0_8
   END DO
   END IF
   ! Add the dissipative and possibly viscous fluxes to the
   ! Euler fluxes. Loop over the owned cells and add fw to dw.
   ! Also multiply by iblank so that no updates occur in holes
   ! or on the overset boundary.
   IF (lowspeedpreconditioner) THEN
   dwod = 0.0_8
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   !    Compute speed of sound
   arg1d = ((gammad(i, j, k)*p(i, j, k)+gamma(i, j, k)*pd(i, j, k&
   &           ))*w(i, j, k, irho)-gamma(i, j, k)*p(i, j, k)*wd(i, j, k, &
   &           irho))/w(i, j, k, irho)**2
   arg1 = gamma(i, j, k)*p(i, j, k)/w(i, j, k, irho)
   IF (arg1 .EQ. 0.0_8) THEN
   sosd = 0.0_8
   ELSE
   sosd = arg1d/(2.0*SQRT(arg1))
   END IF
   sos = SQRT(arg1)
   ! Coompute velocities without rho from state vector
   velxrhod = wd(i, j, k, ivx)
   velxrho = w(i, j, k, ivx)
   velyrhod = wd(i, j, k, ivy)
   velyrho = w(i, j, k, ivy)
   velzrhod = wd(i, j, k, ivz)
   velzrho = w(i, j, k, ivz)
   qd = 2*velxrho*velxrhod + 2*velyrho*velyrhod + 2*velzrho*&
   &           velzrhod
   q = velxrho**2 + velyrho**2 + velzrho**2
   IF (q .EQ. 0.0_8) THEN
   result1d = 0.0_8
   ELSE
   result1d = qd/(2.0*SQRT(q))
   END IF
   result1 = SQRT(q)
   resmd = (result1d*sos-result1*sosd)/sos**2
   resm = result1/sos
   !
   !    Compute K3
   k3d = (1-k1*m0**2)*2*resm*resmd/m0**4
   k3 = k1*(1+(1-k1*m0**2)*resm**2/(k1*m0**4))
   IF (k3*(velxrho**2+velyrho**2+velzrho**2) .LT. k2*(winf(ivx)**&
   &             2+winf(ivy)**2+winf(ivz)**2)) THEN
   x1d = k2*(2*winf(ivx)*winfd(ivx)+2*winf(ivy)*winfd(ivy)+2*&
   &             winf(ivz)*winfd(ivz))
   x1 = k2*(winf(ivx)**2+winf(ivy)**2+winf(ivz)**2)
   ELSE
   x1d = k3d*(velxrho**2+velyrho**2+velzrho**2) + k3*(2*velxrho&
   &             *velxrhod+2*velyrho*velyrhod+2*velzrho*velzrhod)
   x1 = k3*(velxrho**2+velyrho**2+velzrho**2)
   END IF
   IF (x1 .GT. sos**2) THEN
   betamr2d = 2*sos*sosd
   betamr2 = sos**2
   ELSE
   betamr2d = x1d
   betamr2 = x1
   END IF
   a11d = betamr2d/sos**4 - betamr2*4*sosd/sos**5
   a11 = betamr2*(1/sos**4)
   a12 = zero
   a13 = zero
   a14 = zero
   a15d = (betamr2*4*sos**3*sosd-betamr2d*sos**4)/(sos**4)**2
   a15 = (-betamr2)/sos**4
   a21d = (one*velxrhod*sos**2-one*velxrho*2*sos*sosd)/(sos**2)**&
   &           2
   a21 = one*velxrho/sos**2
   a22d = one*wd(i, j, k, irho)
   a22 = one*w(i, j, k, irho)
   a23 = zero
   a24 = zero
   a25d = (one*velxrho*2*sos*sosd-one*velxrhod*sos**2)/(sos**2)**&
   &           2
   a25 = one*(-velxrho)/sos**2
   a31d = (one*velyrhod*sos**2-one*velyrho*2*sos*sosd)/(sos**2)**&
   &           2
   a31 = one*velyrho/sos**2
   a32 = zero
   a33d = one*wd(i, j, k, irho)
   a33 = one*w(i, j, k, irho)
   a34 = zero
   a35d = (one*velyrho*2*sos*sosd-one*velyrhod*sos**2)/(sos**2)**&
   &           2
   a35 = one*(-velyrho)/sos**2
   a41d = (one*velzrhod*sos**2-one*velzrho*2*sos*sosd)/(sos**2)**&
   &           2
   a41 = one*velzrho/sos**2
   a42 = zero
   a43 = zero
   a44d = one*wd(i, j, k, irho)
   a44 = one*w(i, j, k, irho)
   a45d = (one*velzrho*2*sos*sosd-one*velzrhod*sos**2)/(sos**2)**&
   &           2
   a45 = zero + one*(-velzrho)/sos**2
   a51d = one*((-gammad(i, j, k))/(gamma(i, j, k)-1)**2+2*resm*&
   &           resmd/2)
   a51 = one*(1/(gamma(i, j, k)-1)+resm**2/2)
   a52d = one*(wd(i, j, k, irho)*velxrho+w(i, j, k, irho)*&
   &           velxrhod)
   a52 = one*w(i, j, k, irho)*velxrho
   a53d = one*(wd(i, j, k, irho)*velyrho+w(i, j, k, irho)*&
   &           velyrhod)
   a53 = one*w(i, j, k, irho)*velyrho
   a54d = one*(wd(i, j, k, irho)*velzrho+w(i, j, k, irho)*&
   &           velzrhod)
   a54 = one*w(i, j, k, irho)*velzrho
   a55d = -(one*resm*resmd)
   a55 = one*((-(resm**2))/2)
   b11d = ((a11d*q+a11*qd)*(gamma(i, j, k)-1)+a11*q*gammad(i, j, &
   &           k))/2 + (a12*velxrho*wd(i, j, k, irho)-a12*velxrhod*w(i, j, &
   &           k, irho))/w(i, j, k, irho)**2 + (a13*velyrho*wd(i, j, k, &
   &           irho)-a13*velyrhod*w(i, j, k, irho))/w(i, j, k, irho)**2 + (&
   &           a14*velzrho*wd(i, j, k, irho)-a14*velzrhod*w(i, j, k, irho))&
   &           /w(i, j, k, irho)**2 + a15d*((gamma(i, j, k)-1)*q/2-sos**2) &
   &           + a15*((gammad(i, j, k)*q+(gamma(i, j, k)-1)*qd)/2-2*sos*&
   &           sosd)
   b11 = a11*(gamma(i, j, k)-1)*q/2 + a12*(-velxrho)/w(i, j, k, &
   &           irho) + a13*(-velyrho)/w(i, j, k, irho) + a14*(-velzrho)/w(i&
   &           , j, k, irho) + a15*((gamma(i, j, k)-1)*q/2-sos**2)
   b12d = (a11d*velxrho+a11*velxrhod)*(1-gamma(i, j, k)) - a11*&
   &           velxrho*gammad(i, j, k) - a12*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a15d*velxrho+a15*velxrhod)*(1-gamma(i, j, k)) - &
   &           a15*velxrho*gammad(i, j, k)
   b12 = a11*(1-gamma(i, j, k))*velxrho + a12*1/w(i, j, k, irho) &
   &           + a15*(1-gamma(i, j, k))*velxrho
   b13d = (a11d*velyrho+a11*velyrhod)*(1-gamma(i, j, k)) - a11*&
   &           velyrho*gammad(i, j, k) - a13*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a15d*velyrho+a15*velyrhod)*(1-gamma(i, j, k)) - &
   &           a15*velyrho*gammad(i, j, k)
   b13 = a11*(1-gamma(i, j, k))*velyrho + a13/w(i, j, k, irho) + &
   &           a15*(1-gamma(i, j, k))*velyrho
   b14d = (a11d*velzrho+a11*velzrhod)*(1-gamma(i, j, k)) - a11*&
   &           velzrho*gammad(i, j, k) - a14*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a15d*velzrho+a15*velzrhod)*(1-gamma(i, j, k)) - &
   &           a15*velzrho*gammad(i, j, k)
   b14 = a11*(1-gamma(i, j, k))*velzrho + a14/w(i, j, k, irho) + &
   &           a15*(1-gamma(i, j, k))*velzrho
   b15d = a11d*(gamma(i, j, k)-1) + a11*gammad(i, j, k) + a15d*(&
   &           gamma(i, j, k)-1) + a15*gammad(i, j, k)
   b15 = a11*(gamma(i, j, k)-1) + a15*(gamma(i, j, k)-1)
   b21d = ((a21d*q+a21*qd)*(gamma(i, j, k)-1)+a21*q*gammad(i, j, &
   &           k))/2 + ((-(a22d*velxrho)-a22*velxrhod)*w(i, j, k, irho)+a22&
   &           *velxrho*wd(i, j, k, irho))/w(i, j, k, irho)**2 + (a23*&
   &           velyrho*wd(i, j, k, irho)-a23*velyrhod*w(i, j, k, irho))/w(i&
   &           , j, k, irho)**2 + (a24*velzrho*wd(i, j, k, irho)-a24*&
   &           velzrhod*w(i, j, k, irho))/w(i, j, k, irho)**2 + a25d*((&
   &           gamma(i, j, k)-1)*q/2-sos**2) + a25*((gammad(i, j, k)*q+(&
   &           gamma(i, j, k)-1)*qd)/2-2*sos*sosd)
   b21 = a21*(gamma(i, j, k)-1)*q/2 + a22*(-velxrho)/w(i, j, k, &
   &           irho) + a23*(-velyrho)/w(i, j, k, irho) + a24*(-velzrho)/w(i&
   &           , j, k, irho) + a25*((gamma(i, j, k)-1)*q/2-sos**2)
   b22d = (a21d*velxrho+a21*velxrhod)*(1-gamma(i, j, k)) - a21*&
   &           velxrho*gammad(i, j, k) + (a22d*w(i, j, k, irho)-a22*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a25d*velxrho+a25*velxrhod&
   &           )*(1-gamma(i, j, k)) - a25*velxrho*gammad(i, j, k)
   b22 = a21*(1-gamma(i, j, k))*velxrho + a22/w(i, j, k, irho) + &
   &           a25*(1-gamma(i, j, k))*velxrho
   b23d = (a21d*velyrho+a21*velyrhod)*(1-gamma(i, j, k)) - a21*&
   &           velyrho*gammad(i, j, k) - a23*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a25d*velyrho+a25*velyrhod)*(1-gamma(i, j, k)) - &
   &           a25*velyrho*gammad(i, j, k)
   b23 = a21*(1-gamma(i, j, k))*velyrho + a23*1/w(i, j, k, irho) &
   &           + a25*(1-gamma(i, j, k))*velyrho
   b24d = (a21d*velzrho+a21*velzrhod)*(1-gamma(i, j, k)) - a21*&
   &           velzrho*gammad(i, j, k) - a24*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a25d*velzrho+a25*velzrhod)*(1-gamma(i, j, k)) - &
   &           a25*velzrho*gammad(i, j, k)
   b24 = a21*(1-gamma(i, j, k))*velzrho + a24*1/w(i, j, k, irho) &
   &           + a25*(1-gamma(i, j, k))*velzrho
   b25d = a21d*(gamma(i, j, k)-1) + a21*gammad(i, j, k) + a25d*(&
   &           gamma(i, j, k)-1) + a25*gammad(i, j, k)
   b25 = a21*(gamma(i, j, k)-1) + a25*(gamma(i, j, k)-1)
   b31d = ((a31d*q+a31*qd)*(gamma(i, j, k)-1)+a31*q*gammad(i, j, &
   &           k))/2 + (a32*velxrho*wd(i, j, k, irho)-a32*velxrhod*w(i, j, &
   &           k, irho))/w(i, j, k, irho)**2 + ((-(a33d*velyrho)-a33*&
   &           velyrhod)*w(i, j, k, irho)+a33*velyrho*wd(i, j, k, irho))/w(&
   &           i, j, k, irho)**2 + (a34*velzrho*wd(i, j, k, irho)-a34*&
   &           velzrhod*w(i, j, k, irho))/w(i, j, k, irho)**2 + a35d*((&
   &           gamma(i, j, k)-1)*q/2-sos**2) + a35*((gammad(i, j, k)*q+(&
   &           gamma(i, j, k)-1)*qd)/2-2*sos*sosd)
   b31 = a31*(gamma(i, j, k)-1)*q/2 + a32*(-velxrho)/w(i, j, k, &
   &           irho) + a33*(-velyrho)/w(i, j, k, irho) + a34*(-velzrho)/w(i&
   &           , j, k, irho) + a35*((gamma(i, j, k)-1)*q/2-sos**2)
   b32d = (a31d*velxrho+a31*velxrhod)*(1-gamma(i, j, k)) - a31*&
   &           velxrho*gammad(i, j, k) - a32*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a35d*velxrho+a35*velxrhod)*(1-gamma(i, j, k)) - &
   &           a35*velxrho*gammad(i, j, k)
   b32 = a31*(1-gamma(i, j, k))*velxrho + a32/w(i, j, k, irho) + &
   &           a35*(1-gamma(i, j, k))*velxrho
   b33d = (a31d*velyrho+a31*velyrhod)*(1-gamma(i, j, k)) - a31*&
   &           velyrho*gammad(i, j, k) + (a33d*w(i, j, k, irho)-a33*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a35d*velyrho+a35*velyrhod&
   &           )*(1-gamma(i, j, k)) - a35*velyrho*gammad(i, j, k)
   b33 = a31*(1-gamma(i, j, k))*velyrho + a33*1/w(i, j, k, irho) &
   &           + a35*(1-gamma(i, j, k))*velyrho
   b34d = (a31d*velzrho+a31*velzrhod)*(1-gamma(i, j, k)) - a31*&
   &           velzrho*gammad(i, j, k) - a34*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a35d*velzrho+a35*velzrhod)*(1-gamma(i, j, k)) - &
   &           a35*velzrho*gammad(i, j, k)
   b34 = a31*(1-gamma(i, j, k))*velzrho + a34*1/w(i, j, k, irho) &
   &           + a35*(1-gamma(i, j, k))*velzrho
   b35d = a31d*(gamma(i, j, k)-1) + a31*gammad(i, j, k) + a35d*(&
   &           gamma(i, j, k)-1) + a35*gammad(i, j, k)
   b35 = a31*(gamma(i, j, k)-1) + a35*(gamma(i, j, k)-1)
   b41d = ((a41d*q+a41*qd)*(gamma(i, j, k)-1)+a41*q*gammad(i, j, &
   &           k))/2 + (a42*velxrho*wd(i, j, k, irho)-a42*velxrhod*w(i, j, &
   &           k, irho))/w(i, j, k, irho)**2 + (a43*velyrho*wd(i, j, k, &
   &           irho)-a43*velyrhod*w(i, j, k, irho))/w(i, j, k, irho)**2 + (&
   &           (-(a44d*velzrho)-a44*velzrhod)*w(i, j, k, irho)+a44*velzrho*&
   &           wd(i, j, k, irho))/w(i, j, k, irho)**2 + a45d*((gamma(i, j, &
   &           k)-1)*q/2-sos**2) + a45*((gammad(i, j, k)*q+(gamma(i, j, k)-&
   &           1)*qd)/2-2*sos*sosd)
   b41 = a41*(gamma(i, j, k)-1)*q/2 + a42*(-velxrho)/w(i, j, k, &
   &           irho) + a43*(-velyrho)/w(i, j, k, irho) + a44*(-velzrho)/w(i&
   &           , j, k, irho) + a45*((gamma(i, j, k)-1)*q/2-sos**2)
   b42d = (a41d*velxrho+a41*velxrhod)*(1-gamma(i, j, k)) - a41*&
   &           velxrho*gammad(i, j, k) - a42*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a45d*velxrho+a45*velxrhod)*(1-gamma(i, j, k)) - &
   &           a45*velxrho*gammad(i, j, k)
   b42 = a41*(1-gamma(i, j, k))*velxrho + a42/w(i, j, k, irho) + &
   &           a45*(1-gamma(i, j, k))*velxrho
   b43d = (a41d*velyrho+a41*velyrhod)*(1-gamma(i, j, k)) - a41*&
   &           velyrho*gammad(i, j, k) - a43*wd(i, j, k, irho)/w(i, j, k, &
   &           irho)**2 + (a45d*velyrho+a45*velyrhod)*(1-gamma(i, j, k)) - &
   &           a45*velyrho*gammad(i, j, k)
   b43 = a41*(1-gamma(i, j, k))*velyrho + a43*1/w(i, j, k, irho) &
   &           + a45*(1-gamma(i, j, k))*velyrho
   b44d = (a41d*velzrho+a41*velzrhod)*(1-gamma(i, j, k)) - a41*&
   &           velzrho*gammad(i, j, k) + (a44d*w(i, j, k, irho)-a44*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a45d*velzrho+a45*velzrhod&
   &           )*(1-gamma(i, j, k)) - a45*velzrho*gammad(i, j, k)
   b44 = a41*(1-gamma(i, j, k))*velzrho + a44*1/w(i, j, k, irho) &
   &           + a45*(1-gamma(i, j, k))*velzrho
   b45d = a41d*(gamma(i, j, k)-1) + a41*gammad(i, j, k) + a45d*(&
   &           gamma(i, j, k)-1) + a45*gammad(i, j, k)
   b45 = a41*(gamma(i, j, k)-1) + a45*(gamma(i, j, k)-1)
   b51d = ((a51d*q+a51*qd)*(gamma(i, j, k)-1)+a51*q*gammad(i, j, &
   &           k))/2 + ((-(a52d*velxrho)-a52*velxrhod)*w(i, j, k, irho)+a52&
   &           *velxrho*wd(i, j, k, irho))/w(i, j, k, irho)**2 + ((-(a53d*&
   &           velyrho)-a53*velyrhod)*w(i, j, k, irho)+a53*velyrho*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + ((-(a54d*velzrho)-a54*&
   &           velzrhod)*w(i, j, k, irho)+a54*velzrho*wd(i, j, k, irho))/w(&
   &           i, j, k, irho)**2 + a55d*((gamma(i, j, k)-1)*q/2-sos**2) + &
   &           a55*((gammad(i, j, k)*q+(gamma(i, j, k)-1)*qd)/2-2*sos*sosd)
   b51 = a51*(gamma(i, j, k)-1)*q/2 + a52*(-velxrho)/w(i, j, k, &
   &           irho) + a53*(-velyrho)/w(i, j, k, irho) + a54*(-velzrho)/w(i&
   &           , j, k, irho) + a55*((gamma(i, j, k)-1)*q/2-sos**2)
   b52d = (a51d*velxrho+a51*velxrhod)*(1-gamma(i, j, k)) - a51*&
   &           velxrho*gammad(i, j, k) + (a52d*w(i, j, k, irho)-a52*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a55d*velxrho+a55*velxrhod&
   &           )*(1-gamma(i, j, k)) - a55*velxrho*gammad(i, j, k)
   b52 = a51*(1-gamma(i, j, k))*velxrho + a52/w(i, j, k, irho) + &
   &           a55*(1-gamma(i, j, k))*velxrho
   b53d = (a51d*velyrho+a51*velyrhod)*(1-gamma(i, j, k)) - a51*&
   &           velyrho*gammad(i, j, k) + (a53d*w(i, j, k, irho)-a53*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a55d*velyrho+a55*velyrhod&
   &           )*(1-gamma(i, j, k)) - a55*velyrho*gammad(i, j, k)
   b53 = a51*(1-gamma(i, j, k))*velyrho + a53*1/w(i, j, k, irho) &
   &           + a55*(1-gamma(i, j, k))*velyrho
   b54d = (a51d*velzrho+a51*velzrhod)*(1-gamma(i, j, k)) - a51*&
   &           velzrho*gammad(i, j, k) + (a54d*w(i, j, k, irho)-a54*wd(i, j&
   &           , k, irho))/w(i, j, k, irho)**2 + (a55d*velzrho+a55*velzrhod&
   &           )*(1-gamma(i, j, k)) - a55*velzrho*gammad(i, j, k)
   b54 = a51*(1-gamma(i, j, k))*velzrho + a54*1/w(i, j, k, irho) &
   &           + a55*(1-gamma(i, j, k))*velzrho
   b55d = a51d*(gamma(i, j, k)-1) + a51*gammad(i, j, k) + a55d*(&
   &           gamma(i, j, k)-1) + a55*gammad(i, j, k)
   b55 = a51*(gamma(i, j, k)-1) + a55*(gamma(i, j, k)-1)
   ! dwo is the orginal redisual
   DO l=1,nwf
   dwod(l) = REAL(iblank(i, j, k), realtype)*(dwd(i, j, k, l)+&
   &             fwd(i, j, k, l))
   dwo(l) = (dw(i, j, k, l)+fw(i, j, k, l))*REAL(iblank(i, j, k&
   &             ), realtype)
   END DO
   dwd(i, j, k, 1) = b11d*dwo(1) + b11*dwod(1) + b12d*dwo(2) + &
   &           b12*dwod(2) + b13d*dwo(3) + b13*dwod(3) + b14d*dwo(4) + b14*&
   &           dwod(4) + b15d*dwo(5) + b15*dwod(5)
   dw(i, j, k, 1) = b11*dwo(1) + b12*dwo(2) + b13*dwo(3) + b14*&
   &           dwo(4) + b15*dwo(5)
   dwd(i, j, k, 2) = b21d*dwo(1) + b21*dwod(1) + b22d*dwo(2) + &
   &           b22*dwod(2) + b23d*dwo(3) + b23*dwod(3) + b24d*dwo(4) + b24*&
   &           dwod(4) + b25d*dwo(5) + b25*dwod(5)
   dw(i, j, k, 2) = b21*dwo(1) + b22*dwo(2) + b23*dwo(3) + b24*&
   &           dwo(4) + b25*dwo(5)
   dwd(i, j, k, 3) = b31d*dwo(1) + b31*dwod(1) + b32d*dwo(2) + &
   &           b32*dwod(2) + b33d*dwo(3) + b33*dwod(3) + b34d*dwo(4) + b34*&
   &           dwod(4) + b35d*dwo(5) + b35*dwod(5)
   dw(i, j, k, 3) = b31*dwo(1) + b32*dwo(2) + b33*dwo(3) + b34*&
   &           dwo(4) + b35*dwo(5)
   dwd(i, j, k, 4) = b41d*dwo(1) + b41*dwod(1) + b42d*dwo(2) + &
   &           b42*dwod(2) + b43d*dwo(3) + b43*dwod(3) + b44d*dwo(4) + b44*&
   &           dwod(4) + b45d*dwo(5) + b45*dwod(5)
   dw(i, j, k, 4) = b41*dwo(1) + b42*dwo(2) + b43*dwo(3) + b44*&
   &           dwo(4) + b45*dwo(5)
   dwd(i, j, k, 5) = b51d*dwo(1) + b51*dwod(1) + b52d*dwo(2) + &
   &           b52*dwod(2) + b53d*dwo(3) + b53*dwod(3) + b54d*dwo(4) + b54*&
   &           dwod(4) + b55d*dwo(5) + b55*dwod(5)
   dw(i, j, k, 5) = b51*dwo(1) + b52*dwo(2) + b53*dwo(3) + b54*&
   &           dwo(4) + b55*dwo(5)
   END DO
   END DO
   END DO
   ELSE
   DO l=1,nwf
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   dwd(i, j, k, l) = REAL(iblank(i, j, k), realtype)*(dwd(i, j&
   &             , k, l)+fwd(i, j, k, l))
   dw(i, j, k, l) = (dw(i, j, k, l)+fw(i, j, k, l))*REAL(iblank&
   &             (i, j, k), realtype)
   END DO
   END DO
   END DO
   END DO
   END IF
   END SUBROUTINE RESIDUAL_BLOCK_D
