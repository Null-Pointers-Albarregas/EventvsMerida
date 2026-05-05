import { Directive, ElementRef, Input, OnInit, OnDestroy } from '@angular/core';

@Directive({
  selector: '[appReveal]',
  standalone: true
})
export class RevealDirective implements OnInit, OnDestroy {
  @Input() revealDelay: number = 0;
  @Input() revealDirection: 'up' | 'left' | 'right' | 'scale' = 'up';

  private observer!: IntersectionObserver;

  constructor(private el: ElementRef) {}

  ngOnInit() {
    const el = this.el.nativeElement as HTMLElement;
    el.classList.add('reveal');

    if (this.revealDirection === 'left') el.classList.add('from-left');
    if (this.revealDirection === 'right') el.classList.add('from-right');
    if (this.revealDirection === 'scale') el.classList.add('scale-in');
    if (this.revealDelay > 0) el.classList.add(`reveal-delay-${this.revealDelay}`);

    this.observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('visible');
          return;
        }

        el.classList.remove('visible');
      },
      { threshold: 0.15, rootMargin: '0px 0px -60px 0px' }
    );

    this.observer.observe(el);
  }

  ngOnDestroy() {
    this.observer?.disconnect();
  }
}
