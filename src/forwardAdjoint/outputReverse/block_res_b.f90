   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of block_res in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *(flowdoms.x) *(flowdoms.w)
   !                *(flowdoms.dw) *(*bcdata.fp) *(*bcdata.fv) *(*bcdata.m)
   !                *(*bcdata.sepsensor) *(*bcdata.cavitation) moment
   !                force cavitation sepsensor
   !   with respect to varying inputs: *(flowdoms.x) *(flowdoms.w)
   !                *(flowdoms.dw) *(*bcdata.fp) *(*bcdata.fv) *(*bcdata.m)
   !                *(*bcdata.sepsensor) *(*bcdata.cavitation) pref
   !                mach tempfreestream lengthref machcoef pointref
   !                moment alpha force beta cavitation sepsensor
   !   RW status of diff variables: *(flowdoms.x):in-out *(flowdoms.w):in-out
   !                *(flowdoms.dw):in-out *rev:(loc) *p:(loc) *gamma:(loc)
   !                *rlv:(loc) *fw:(loc) *(*viscsubface.tau):(loc)
   !                *(*bcdata.fp):in-out *(*bcdata.fv):in-out *(*bcdata.m):in-out
   !                *(*bcdata.sepsensor):in-out *(*bcdata.cavitation):in-out
   !                *radi:(loc) *radj:(loc) *radk:(loc) mudim:(loc)
   !                gammainf:(loc) pinf:(loc) timeref:(loc) rhoinf:(loc)
   !                muref:(loc) rhoinfdim:(loc) tref:(loc) winf:(loc)
   !                muinf:(loc) uinf:(loc) pinfcorr:(loc) rgas:(loc)
   !                pinfdim:(loc) pref:out rhoref:(loc) mach:out tempfreestream:out
   !                veldirfreestream:(loc) lengthref:out machcoef:out
   !                pointref:out moment:in-zero alpha:out force:in-zero
   !                beta:out cavitation:in-zero sepsensor:in-zero
   !   Plus diff mem management of: flowdoms.x:in flowdoms.w:in flowdoms.dw:in
   !                rev:in p:in gamma:in rlv:in fw:in viscsubface:in
   !                *viscsubface.tau:in bcdata:in *bcdata.fp:in *bcdata.fv:in
   !                *bcdata.m:in *bcdata.sepsensor:in *bcdata.cavitation:in
   !                radi:in radj:in radk:in
   ! This is a super-combined function that combines the original
   ! functionality of: 
   ! Pressure Computation
   ! timeStep
   ! applyAllBCs
   ! initRes
   ! residual 
   ! The real difference between this and the original modules is that it
   ! it only operates on a single block at a time and as such the nominal
   ! block/sps loop is outside the calculation. This routine is suitable
   ! for forward mode AD with Tapenade
   SUBROUTINE BLOCK_RES_B(nn, sps, usespatial, alpha, alphab, beta, betab, &
   & liftindex, force, forceb, moment, momentb, sepsensor, sepsensorb, &
   & cavitation, cavitationb)
   USE BLOCKPOINTERS_B
   USE FLOWVARREFSTATE
   USE INPUTPHYSICS
   USE INPUTTIMESPECTRAL
   USE SECTION
   USE MONITOR
   USE ITERATION
   USE INPUTADJOINT
   USE DIFFSIZES
   IMPLICIT NONE
   !call getCostFunction(costFunction, force, moment, sepSensor, &
   !alpha, beta, liftIndex, objValue)
   ! Input Arguments:
   INTEGER(kind=inttype), INTENT(IN) :: nn, sps
   LOGICAL, INTENT(IN) :: usespatial
   REAL(kind=realtype), INTENT(IN) :: alpha, beta
   REAL(kind=realtype) :: alphab, betab
   INTEGER(kind=inttype), INTENT(IN) :: liftindex
   ! Output Variables
   REAL(kind=realtype) :: force(3), moment(3), sepsensor, cavitation
   REAL(kind=realtype) :: forceb(3), momentb(3), sepsensorb, cavitationb
   ! Working Variables
   REAL(kind=realtype) :: gm1, v2, fact, tmp
   REAL(kind=realtype) :: v2b, factb, tmpb
   INTEGER(kind=inttype) :: i, j, k, sps2, mm, l, ii, ll, jj
   INTEGER(kind=inttype) :: nstate
   REAL(kind=realtype), DIMENSION(nsections) :: t
   LOGICAL :: useoldcoor
   REAL(kind=realtype), DIMENSION(3) :: cfp, cfv, cmp, cmv
   REAL(kind=realtype), DIMENSION(3) :: cfpb, cfvb, cmpb, cmvb
   REAL(kind=realtype) :: yplusmax, scaledim
   REAL(kind=realtype) :: scaledimb
   INTRINSIC MAX
   INTEGER :: branch
   REAL(kind=realtype) :: temp1
   REAL(kind=realtype) :: temp0
   REAL(kind=realtype) :: tempb5
   REAL(kind=realtype) :: tempb4
   REAL(kind=realtype) :: tempb3(3)
   REAL(kind=realtype) :: tempb2
   REAL(kind=realtype) :: tempb1(3)
   REAL(kind=realtype) :: tempb0
   REAL(kind=realtype) :: tempb
   INTEGER :: ii3
   INTEGER :: ii2
   INTEGER :: ii1
   REAL(kind=realtype) :: temp
   ! Setup number of state variable based on turbulence assumption
   IF (frozenturbulence) THEN
   nstate = nwf
   ELSE
   nstate = nw
   END IF
   ! Set pointers to input/output variables
   wb => flowdomsb(nn, currentlevel, sps)%w
   w => flowdoms(nn, currentlevel, sps)%w
   dwb => flowdomsb(nn, 1, sps)%dw
   dw => flowdoms(nn, 1, sps)%dw
   xb => flowdomsb(nn, currentlevel, sps)%x
   x => flowdoms(nn, currentlevel, sps)%x
   vol => flowdoms(nn, currentlevel, sps)%vol
   ! ------------------------------------------------
   !        Additional 'Extra' Components
   ! ------------------------------------------------ 
   CALL ADJUSTINFLOWANGLE(alpha, beta, liftindex)
   CALL PUSHREAL8(rhoref)
   CALL PUSHREAL8(pref)
   CALL PUSHREAL8(tref)
   CALL PUSHREAL8(gammainf)
   CALL REFERENCESTATE()
   CALL SETFLOWINFINITYSTATE()
   ! ------------------------------------------------
   !        Normal Residual Computation
   ! ------------------------------------------------
   ! Compute the pressures
   gm1 = gammaconstant - one
   ! Compute P 
   DO k=0,kb
   DO j=0,jb
   DO i=0,ib
   CALL PUSHREAL8(v2)
   v2 = w(i, j, k, ivx)**2 + w(i, j, k, ivy)**2 + w(i, j, k, ivz)**&
   &         2
   p(i, j, k) = gm1*(w(i, j, k, irhoe)-half*w(i, j, k, irho)*v2)
   IF (p(i, j, k) .LT. 1.e-4_realType*pinfcorr) THEN
   p(i, j, k) = 1.e-4_realType*pinfcorr
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   p(i, j, k) = p(i, j, k)
   END IF
   END DO
   END DO
   END DO
   ! Compute Laminar/eddy viscosity if required
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL COMPUTELAMVISCOSITY()
   CALL COMPUTEEDDYVISCOSITY()
   !  Apply all BC's
   CALL PUSHREAL8ARRAY(sk, SIZE(sk, 1)*SIZE(sk, 2)*SIZE(sk, 3)*SIZE(sk, 4&
   &               ))
   CALL PUSHREAL8ARRAY(sj, SIZE(sj, 1)*SIZE(sj, 2)*SIZE(sj, 3)*SIZE(sj, 4&
   &               ))
   CALL PUSHREAL8ARRAY(si, SIZE(si, 1)*SIZE(si, 2)*SIZE(si, 3)*SIZE(si, 4&
   &               ))
   CALL PUSHREAL8ARRAY(rlv, SIZE(rlv, 1)*SIZE(rlv, 2)*SIZE(rlv, 3))
   CALL PUSHREAL8ARRAY(gamma, SIZE(gamma, 1)*SIZE(gamma, 2)*SIZE(gamma, 3&
   &               ))
   CALL PUSHREAL8ARRAY(s, SIZE(s, 1)*SIZE(s, 2)*SIZE(s, 3)*SIZE(s, 4))
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL PUSHREAL8ARRAY(rev, SIZE(rev, 1)*SIZE(rev, 2)*SIZE(rev, 3))
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                     , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, &
   &                     2)*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(&
   &                     flowdoms(ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   CALL APPLYALLBC_BLOCK(.true.)
   ! Compute skin_friction Velocity (only for wall Functions)
   ! #ifndef 1
   !   call computeUtau_block
   ! #endif
   ! Compute time step and spectral radius
   CALL PUSHREAL8ARRAY(radk, SIZE(radk, 1)*SIZE(radk, 2)*SIZE(radk, 3))
   CALL PUSHREAL8ARRAY(radj, SIZE(radj, 1)*SIZE(radj, 2)*SIZE(radj, 3))
   CALL PUSHREAL8ARRAY(radi, SIZE(radi, 1)*SIZE(radi, 2)*SIZE(radi, 3))
   CALL TIMESTEP_BLOCK(.false.)
   spectralloop0:DO sps2=1,ntimeintervalsspectral
   flowdoms(nn, 1, sps2)%dw(:, :, :, :) = zero
   END DO spectralloop0
   ! -------------------------------
   ! Compute turbulence residual for RANS equations
   IF (equations .EQ. ransequations) THEN
   SELECT CASE  (turbmodel) 
   CASE (spalartallmaras) 
   !call determineDistance2(1, sps)
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%dw, SIZE(&
   &                         flowdoms(ii3, ii2, ii1)%dw, 1)*SIZE(flowdoms(&
   &                         ii3, ii2, ii1)%dw, 2)*SIZE(flowdoms(ii3, ii2, &
   &                         ii1)%dw, 3)*SIZE(flowdoms(ii3, ii2, ii1)%dw, 4&
   &                         ))
   END DO
   END DO
   END DO
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms&
   &                         (ii3, ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, &
   &                         ii1)%w, 2)*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*&
   &                         SIZE(flowdoms(ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   CALL SA_BLOCK(.true.)
   CALL PUSHCONTROL2B(0)
   CASE DEFAULT
   CALL PUSHCONTROL2B(1)
   END SELECT
   ELSE
   CALL PUSHCONTROL2B(2)
   END IF
   ! -------------------------------  
   ! Next initialize residual for flow variables. The is the only place
   ! where there is an n^2 dependance. There are issues with
   ! initRes. So only the necesary timespectral code has been copied
   ! here. See initres for more information and comments.
   ! sps here is the on-spectral instance
   IF (ntimeintervalsspectral .EQ. 1) THEN
   dw(:, :, :, 1:nwf) = zero
   CALL PUSHCONTROL1B(0)
   ELSE
   ! Zero dw on all spectral instances
   spectralloop1:DO sps2=1,ntimeintervalsspectral
   flowdoms(nn, 1, sps2)%dw(:, :, :, 1:nwf) = zero
   END DO spectralloop1
   spectralloop2:DO sps2=1,ntimeintervalsspectral
   CALL PUSHINTEGER4(jj)
   jj = sectionid
   timeloopfine:DO mm=1,ntimeintervalsspectral
   CALL PUSHINTEGER4(ii)
   ii = 3*(mm-1)
   varloopfine:DO l=1,nwf
   IF ((l .EQ. ivx .OR. l .EQ. ivy) .OR. l .EQ. ivz) THEN
   IF (l .EQ. ivx) THEN
   CALL PUSHINTEGER4(ll)
   ll = 3*sps2 - 2
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (l .EQ. ivy) THEN
   CALL PUSHINTEGER4(ll)
   ll = 3*sps2 - 1
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (l .EQ. ivz) THEN
   CALL PUSHINTEGER4(ll)
   ll = 3*sps2
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   CALL PUSHREAL8(tmp)
   tmp = dvector(jj, ll, ii+1)*flowdoms(nn, 1, mm)%w(i, j&
   &                   , k, ivx) + dvector(jj, ll, ii+2)*flowdoms(nn, 1, mm&
   &                   )%w(i, j, k, ivy) + dvector(jj, ll, ii+3)*flowdoms(&
   &                   nn, 1, mm)%w(i, j, k, ivz)
   flowdoms(nn, 1, sps2)%dw(i, j, k, l) = flowdoms(nn, 1&
   &                   , sps2)%dw(i, j, k, l) + tmp*flowdoms(nn, 1, mm)%vol&
   &                   (i, j, k)*flowdoms(nn, 1, mm)%w(i, j, k, irho)
   END DO
   END DO
   END DO
   CALL PUSHCONTROL1B(1)
   ELSE
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! This is: dw = dw + dscalar*vol*w
   flowdoms(nn, 1, sps2)%dw(i, j, k, l) = flowdoms(nn, 1&
   &                   , sps2)%dw(i, j, k, l) + dscalar(jj, sps2, mm)*&
   &                   flowdoms(nn, 1, mm)%vol(i, j, k)*flowdoms(nn, 1, mm)&
   &                   %w(i, j, k, l)
   END DO
   END DO
   END DO
   CALL PUSHCONTROL1B(0)
   END IF
   END DO varloopfine
   END DO timeloopfine
   END DO spectralloop2
   CALL PUSHCONTROL1B(1)
   END IF
   !  Actual residual calc
   CALL PUSHREAL8ARRAY(fw, SIZE(fw, 1)*SIZE(fw, 2)*SIZE(fw, 3)*SIZE(fw, 4&
   &               ))
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%dw, SIZE(flowdoms(&
   &                     ii3, ii2, ii1)%dw, 1)*SIZE(flowdoms(ii3, ii2, ii1)&
   &                     %dw, 2)*SIZE(flowdoms(ii3, ii2, ii1)%dw, 3)*SIZE(&
   &                     flowdoms(ii3, ii2, ii1)%dw, 4))
   END DO
   END DO
   END DO
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                     , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, &
   &                     2)*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(&
   &                     flowdoms(ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   CALL RESIDUAL_BLOCK()
   CALL PUSHREAL8ARRAY(sk, SIZE(sk, 1)*SIZE(sk, 2)*SIZE(sk, 3)*SIZE(sk, 4&
   &               ))
   CALL PUSHREAL8ARRAY(sj, SIZE(sj, 1)*SIZE(sj, 2)*SIZE(sj, 3)*SIZE(sj, 4&
   &               ))
   CALL PUSHREAL8ARRAY(si, SIZE(si, 1)*SIZE(si, 2)*SIZE(si, 3)*SIZE(si, 4&
   &               ))
   CALL PUSHREAL8ARRAY(d2wall, SIZE(d2wall, 1)*SIZE(d2wall, 2)*SIZE(&
   &               d2wall, 3))
   CALL PUSHREAL8ARRAY(rlv, SIZE(rlv, 1)*SIZE(rlv, 2)*SIZE(rlv, 3))
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL PUSHREAL8ARRAY(rev, SIZE(rev, 1)*SIZE(rev, 2)*SIZE(rev, 3))
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                     , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, &
   &                     2)*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(&
   &                     flowdoms(ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   DO ii1=1,ntimeintervalsspectral
   DO ii2=1,1
   DO ii3=nn,nn
   CALL PUSHREAL8ARRAY(flowdoms(ii3, ii2, ii1)%x, SIZE(flowdoms(ii3&
   &                     , ii2, ii1)%x, 1)*SIZE(flowdoms(ii3, ii2, ii1)%x, &
   &                     2)*SIZE(flowdoms(ii3, ii2, ii1)%x, 3)*SIZE(&
   &                     flowdoms(ii3, ii2, ii1)%x, 4))
   END DO
   END DO
   END DO
   CALL PUSHREAL8ARRAY(cmv, 3)
   CALL PUSHREAL8ARRAY(cmp, 3)
   CALL PUSHREAL8ARRAY(cfv, 3)
   CALL PUSHREAL8ARRAY(cfp, 3)
   CALL FORCESANDMOMENTS(cfp, cfv, cmp, cmv, yplusmax, sepsensor, &
   &                    cavitation)
   ! Convert back to actual forces. Note that even though we use
   ! MachCoef, Lref, and surfaceRef here, they are NOT differented,
   ! since F doesn't actually depend on them. Ideally we would just get
   ! the raw forces and moment form forcesAndMoments. 
   scaledim = pref/pinf
   fact = two/(gammainf*pinf*machcoef*machcoef*surfaceref*lref*lref*&
   &   scaledim)
   CALL PUSHREAL8(fact)
   fact = fact/(lengthref*lref)
   cmpb = 0.0_8
   cmvb = 0.0_8
   tempb1 = momentb/fact
   cmpb = tempb1
   cmvb = tempb1
   factb = SUM(-((cmp+cmv)*tempb1/fact))
   CALL POPREAL8(fact)
   tempb2 = factb/(lref*lengthref)
   lengthrefb = -(fact*tempb2/lengthref)
   cfpb = 0.0_8
   cfvb = 0.0_8
   tempb3 = forceb/fact
   factb = SUM(-((cfp+cfv)*tempb3/fact)) + tempb2
   cfpb = tempb3
   cfvb = tempb3
   temp1 = machcoef**2*scaledim
   temp0 = surfaceref*lref**2
   temp = temp0*gammainf*pinf
   tempb4 = -(two*factb/(temp**2*temp1**2))
   tempb5 = temp1*temp0*tempb4
   gammainfb = pinf*tempb5
   machcoefb = scaledim*temp*2*machcoef*tempb4
   scaledimb = temp*machcoef**2*tempb4
   pinfb = gammainf*tempb5 - pref*scaledimb/pinf**2
   prefb = scaledimb/pinf
   CALL POPREAL8ARRAY(cfp, 3)
   CALL POPREAL8ARRAY(cfv, 3)
   CALL POPREAL8ARRAY(cmp, 3)
   CALL POPREAL8ARRAY(cmv, 3)
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%x, SIZE(flowdoms(ii3&
   &                    , ii2, ii1)%x, 1)*SIZE(flowdoms(ii3, ii2, ii1)%x, 2&
   &                    )*SIZE(flowdoms(ii3, ii2, ii1)%x, 3)*SIZE(flowdoms(&
   &                    ii3, ii2, ii1)%x, 4))
   END DO
   END DO
   END DO
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                    , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, 2&
   &                    )*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(flowdoms(&
   &                    ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   CALL POPREAL8ARRAY(rev, SIZE(rev, 1)*SIZE(rev, 2)*SIZE(rev, 3))
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL POPREAL8ARRAY(rlv, SIZE(rlv, 1)*SIZE(rlv, 2)*SIZE(rlv, 3))
   CALL POPREAL8ARRAY(d2wall, SIZE(d2wall, 1)*SIZE(d2wall, 2)*SIZE(d2wall&
   &              , 3))
   CALL POPREAL8ARRAY(si, SIZE(si, 1)*SIZE(si, 2)*SIZE(si, 3)*SIZE(si, 4)&
   &             )
   CALL POPREAL8ARRAY(sj, SIZE(sj, 1)*SIZE(sj, 2)*SIZE(sj, 3)*SIZE(sj, 4)&
   &             )
   CALL POPREAL8ARRAY(sk, SIZE(sk, 1)*SIZE(sk, 2)*SIZE(sk, 3)*SIZE(sk, 4)&
   &             )
   CALL FORCESANDMOMENTS_B(cfp, cfpb, cfv, cfvb, cmp, cmpb, cmv, cmvb, &
   &                   yplusmax, sepsensor, sepsensorb, cavitation, &
   &                   cavitationb)
   DO sps2=ntimeintervalsspectral,1,-1
   DO l=nstate,1,-1
   DO k=kl,2,-1
   DO j=jl,2,-1
   DO i=il,2,-1
   flowdomsb(nn, 1, sps2)%dw(i, j, k, l) = flowdomsb(nn, 1, &
   &             sps2)%dw(i, j, k, l)/flowdoms(nn, currentlevel, sps2)%vol(&
   &             i, j, k)
   END DO
   END DO
   END DO
   END DO
   END DO
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                    , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, 2&
   &                    )*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(flowdoms(&
   &                    ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%dw, SIZE(flowdoms(ii3&
   &                    , ii2, ii1)%dw, 1)*SIZE(flowdoms(ii3, ii2, ii1)%dw&
   &                    , 2)*SIZE(flowdoms(ii3, ii2, ii1)%dw, 3)*SIZE(&
   &                    flowdoms(ii3, ii2, ii1)%dw, 4))
   END DO
   END DO
   END DO
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL POPREAL8ARRAY(fw, SIZE(fw, 1)*SIZE(fw, 2)*SIZE(fw, 3)*SIZE(fw, 4)&
   &             )
   CALL RESIDUAL_BLOCK_B()
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   dwb(:, :, :, 1:nwf) = 0.0_8
   ELSE
   DO sps2=ntimeintervalsspectral,1,-1
   DO mm=ntimeintervalsspectral,1,-1
   DO l=nwf,1,-1
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   DO k=kl,2,-1
   DO j=jl,2,-1
   DO i=il,2,-1
   flowdomsb(nn, 1, mm)%w(i, j, k, l) = flowdomsb(nn, 1, &
   &                   mm)%w(i, j, k, l) + dscalar(jj, sps2, mm)*flowdoms(&
   &                   nn, 1, mm)%vol(i, j, k)*flowdomsb(nn, 1, sps2)%dw(i&
   &                   , j, k, l)
   END DO
   END DO
   END DO
   ELSE
   DO k=kl,2,-1
   DO j=jl,2,-1
   DO i=il,2,-1
   tempb0 = flowdoms(nn, 1, mm)%vol(i, j, k)*flowdomsb(nn&
   &                   , 1, sps2)%dw(i, j, k, l)
   tmpb = flowdoms(nn, 1, mm)%w(i, j, k, irho)*tempb0
   flowdomsb(nn, 1, mm)%w(i, j, k, irho) = flowdomsb(nn, &
   &                   1, mm)%w(i, j, k, irho) + tmp*tempb0
   CALL POPREAL8(tmp)
   flowdomsb(nn, 1, mm)%w(i, j, k, ivx) = flowdomsb(nn, 1&
   &                   , mm)%w(i, j, k, ivx) + dvector(jj, ll, ii+1)*tmpb
   flowdomsb(nn, 1, mm)%w(i, j, k, ivy) = flowdomsb(nn, 1&
   &                   , mm)%w(i, j, k, ivy) + dvector(jj, ll, ii+2)*tmpb
   flowdomsb(nn, 1, mm)%w(i, j, k, ivz) = flowdomsb(nn, 1&
   &                   , mm)%w(i, j, k, ivz) + dvector(jj, ll, ii+3)*tmpb
   END DO
   END DO
   END DO
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) CALL POPINTEGER4(ll)
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) CALL POPINTEGER4(ll)
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) CALL POPINTEGER4(ll)
   END IF
   END DO
   CALL POPINTEGER4(ii)
   END DO
   CALL POPINTEGER4(jj)
   END DO
   DO sps2=ntimeintervalsspectral,1,-1
   flowdomsb(nn, 1, sps2)%dw(:, :, :, 1:nwf) = 0.0_8
   END DO
   END IF
   CALL POPCONTROL2B(branch)
   IF (branch .EQ. 0) THEN
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(&
   &                      ii3, ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)&
   &                      %w, 2)*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(&
   &                      flowdoms(ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%dw, SIZE(flowdoms(&
   &                      ii3, ii2, ii1)%dw, 1)*SIZE(flowdoms(ii3, ii2, ii1&
   &                      )%dw, 2)*SIZE(flowdoms(ii3, ii2, ii1)%dw, 3)*SIZE&
   &                      (flowdoms(ii3, ii2, ii1)%dw, 4))
   END DO
   END DO
   END DO
   CALL SA_BLOCK_B(.true.)
   END IF
   DO sps2=ntimeintervalsspectral,1,-1
   flowdomsb(nn, 1, sps2)%dw = 0.0_8
   END DO
   CALL POPREAL8ARRAY(radi, SIZE(radi, 1)*SIZE(radi, 2)*SIZE(radi, 3))
   CALL POPREAL8ARRAY(radj, SIZE(radj, 1)*SIZE(radj, 2)*SIZE(radj, 3))
   CALL POPREAL8ARRAY(radk, SIZE(radk, 1)*SIZE(radk, 2)*SIZE(radk, 3))
   CALL TIMESTEP_BLOCK_B(.false.)
   DO ii1=ntimeintervalsspectral,1,-1
   DO ii2=1,1,-1
   DO ii3=nn,nn,-1
   CALL POPREAL8ARRAY(flowdoms(ii3, ii2, ii1)%w, SIZE(flowdoms(ii3&
   &                    , ii2, ii1)%w, 1)*SIZE(flowdoms(ii3, ii2, ii1)%w, 2&
   &                    )*SIZE(flowdoms(ii3, ii2, ii1)%w, 3)*SIZE(flowdoms(&
   &                    ii3, ii2, ii1)%w, 4))
   END DO
   END DO
   END DO
   CALL POPREAL8ARRAY(rev, SIZE(rev, 1)*SIZE(rev, 2)*SIZE(rev, 3))
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL POPREAL8ARRAY(s, SIZE(s, 1)*SIZE(s, 2)*SIZE(s, 3)*SIZE(s, 4))
   CALL POPREAL8ARRAY(gamma, SIZE(gamma, 1)*SIZE(gamma, 2)*SIZE(gamma, 3)&
   &             )
   CALL POPREAL8ARRAY(rlv, SIZE(rlv, 1)*SIZE(rlv, 2)*SIZE(rlv, 3))
   CALL POPREAL8ARRAY(si, SIZE(si, 1)*SIZE(si, 2)*SIZE(si, 3)*SIZE(si, 4)&
   &             )
   CALL POPREAL8ARRAY(sj, SIZE(sj, 1)*SIZE(sj, 2)*SIZE(sj, 3)*SIZE(sj, 4)&
   &             )
   CALL POPREAL8ARRAY(sk, SIZE(sk, 1)*SIZE(sk, 2)*SIZE(sk, 3)*SIZE(sk, 4)&
   &             )
   CALL APPLYALLBC_BLOCK_B(.true.)
   CALL COMPUTEEDDYVISCOSITY_B()
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL COMPUTELAMVISCOSITY_B()
   DO k=kb,0,-1
   DO j=jb,0,-1
   DO i=ib,0,-1
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   pinfcorrb = pinfcorrb + 1.e-4_realType*pb(i, j, k)
   pb(i, j, k) = 0.0_8
   END IF
   tempb = gm1*pb(i, j, k)
   wb(i, j, k, irhoe) = wb(i, j, k, irhoe) + tempb
   wb(i, j, k, irho) = wb(i, j, k, irho) - half*v2*tempb
   v2b = -(half*w(i, j, k, irho)*tempb)
   pb(i, j, k) = 0.0_8
   CALL POPREAL8(v2)
   wb(i, j, k, ivx) = wb(i, j, k, ivx) + 2*w(i, j, k, ivx)*v2b
   wb(i, j, k, ivy) = wb(i, j, k, ivy) + 2*w(i, j, k, ivy)*v2b
   wb(i, j, k, ivz) = wb(i, j, k, ivz) + 2*w(i, j, k, ivz)*v2b
   END DO
   END DO
   END DO
   CALL SETFLOWINFINITYSTATE_B()
   CALL POPREAL8(gammainf)
   CALL POPREAL8(tref)
   CALL POPREAL8(pref)
   CALL POPREAL8(rhoref)
   CALL REFERENCESTATE_B()
   CALL ADJUSTINFLOWANGLE_B(alpha, alphab, beta, betab, liftindex)
   momentb = 0.0_8
   forceb = 0.0_8
   cavitationb = 0.0_8
   sepsensorb = 0.0_8
   END SUBROUTINE BLOCK_RES_B
